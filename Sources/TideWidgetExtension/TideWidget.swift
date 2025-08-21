import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let surflineService = EnhancedSurflineService()
    
    func placeholder(in context: Context) -> TideEntry {
        TideEntry(date: Date(), tideData: TideData.placeholder, spotConditions: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TideEntry) -> ()) {
        Task {
            await surflineService.fetchAllSpotsData()
            let data = await convertSurflineTideData(surflineService: surflineService)
            let entry = TideEntry(date: Date(), tideData: data, spotConditions: surflineService.spotConditions)
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            await surflineService.fetchAllSpotsData()
            let data = await convertSurflineTideData(surflineService: surflineService)
            
            var entries: [TideEntry] = []
            let currentDate = Date()
            
            // Create timeline entries for the next 6 hours, updating every 30 minutes
            for minuteOffset in stride(from: 0, to: 360, by: 30) {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                let entry = TideEntry(date: entryDate, tideData: data, spotConditions: surflineService.spotConditions)
                entries.append(entry)
            }
            
            // Refresh timeline after 6 hours
            let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 6, to: currentDate)!))
            completion(timeline)
        }
    }
    
    // Helper function to convert Surfline data
    func convertSurflineTideData(surflineService: EnhancedSurflineService) async -> TideData? {
        guard let pleasurePointId = AppConfig.surflineSpots.first(where: { $0.displayName == "Pleasure Point" })?.id,
              let spotConditions = surflineService.spotConditions[pleasurePointId],
              let surflineTides = spotConditions.tideData else {
            return TideData.placeholder
        }
        
        let now = Date()
        let sortedTides = surflineTides.all.sorted { tide1, tide2 in
            let time1 = Date(timeIntervalSince1970: TimeInterval(tide1.timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(tide2.timestamp ?? 0))
            return time1 < time2
        }
        
        // Calculate current tide state
        var currentHeight = 0.0
        var isRising = true
        var currentType: TidePrediction.TideType = .rising
        
        for i in 0..<sortedTides.count - 1 {
            let time1 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i].timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i+1].timestamp ?? 0))
            
            if now >= time1 && now <= time2 {
                let height1 = sortedTides[i].height ?? 0
                let height2 = sortedTides[i+1].height ?? 0
                let progress = now.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                currentHeight = height1 + (height2 - height1) * progress
                isRising = height2 > height1
                currentType = isRising ? .rising : .falling
                break
            }
        }
        
        // Get upcoming tides
        let upcomingTides = sortedTides.compactMap { tide -> TidePrediction? in
            guard let timestamp = tide.timestamp,
                  let height = tide.height,
                  let type = tide.type else { return nil }
            guard type == "HIGH" || type == "LOW" else { return nil }
            
            let time = Date(timeIntervalSince1970: TimeInterval(timestamp))
            guard time > now else { return nil }
            
            let tideType: TidePrediction.TideType = type == "HIGH" ? .high : .low
            let willRise = type == "LOW"
            
            return TidePrediction(
                time: time,
                height: height,
                type: tideType,
                isRising: willRise
            )
        }.prefix(4).map { $0 }
        
        // Generate hourly predictions
        var hourlyPredictions: [TidePrediction] = []
        for hourOffset in 0..<24 {
            let hourTime = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            var interpolatedHeight = currentHeight
            var interpolatedRising = isRising
            
            for i in 0..<sortedTides.count - 1 {
                let time1 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i].timestamp ?? 0))
                let time2 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i+1].timestamp ?? 0))
                
                if hourTime >= time1 && hourTime <= time2 {
                    let height1 = sortedTides[i].height ?? 0
                    let height2 = sortedTides[i+1].height ?? 0
                    let progress = hourTime.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                    interpolatedHeight = height1 + (height2 - height1) * progress
                    interpolatedRising = height2 > height1
                    break
                }
            }
            
            hourlyPredictions.append(TidePrediction(
                time: hourTime,
                height: interpolatedHeight,
                type: interpolatedRising ? .rising : .falling,
                isRising: interpolatedRising
            ))
        }
        
        return TideData(
            currentTide: TidePrediction(
                time: now,
                height: currentHeight,
                type: currentType,
                isRising: isRising
            ),
            nextTides: upcomingTides,
            hourlyPredictions: hourlyPredictions,
            pleasurePointCondition: SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading",
                spot: .pleasurePoint
            ),
            twentySixthCondition: SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading",
                spot: .twentySixthAve
            ),
            waveData: nil,
            lastUpdated: now
        )
    }
}

struct TideEntry: TimelineEntry {
    let date: Date
    let tideData: TideData?
    let spotConditions: [String: SpotConditions]?
}

struct TideWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

@main
struct TideWidget: Widget {
    let kind: String = "TideWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TideWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("mytides")
        .description("Tide conditions for Pleasure Point and 26th Avenue")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #if os(macOS)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        #endif
    }
}

struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.15, blue: 0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}