import SwiftUI
import AppKit

// Standalone app - to run as app instead of widget, comment out @main in TideWidget.swift
// and uncomment the line below:
// @main
struct TideApp: App {
    init() {
        
        // Ensure the app appears in the dock and becomes active
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Bring window to front
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(.ultraThinMaterial)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 350, height: 400)
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    @State private var tideData: TideData?
    @StateObject private var surflineService = EnhancedSurflineService()
    @State private var isLoading = true
    
    // Convert Surfline tide data to TideData format
    func convertSurflineTideData() async -> TideData? {
        // Use Pleasure Point spot for tide data (could use any spot)
        guard let pleasurePointId = AppConfig.surflineSpots.first(where: { $0.displayName == "Pleasure Point" })?.id,
              let spotConditions = surflineService.spotConditions[pleasurePointId],
              let surflineTides = spotConditions.tideData else {
            return nil
        }
        
        let now = Date()
        
        // Find current tide state
        let sortedTides = surflineTides.all.sorted { tide1, tide2 in
            let time1 = Date(timeIntervalSince1970: TimeInterval(tide1.timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(tide2.timestamp ?? 0))
            return time1 < time2
        }
        
        // Find the tide we're between
        var currentHeight = 0.0
        var isRising = true
        var currentType: TidePrediction.TideType = .rising
        
        for i in 0..<sortedTides.count - 1 {
            let time1 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i].timestamp ?? 0))
            let time2 = Date(timeIntervalSince1970: TimeInterval(sortedTides[i+1].timestamp ?? 0))
            
            if now >= time1 && now <= time2 {
                // Interpolate current height
                let height1 = sortedTides[i].height ?? 0
                let height2 = sortedTides[i+1].height ?? 0
                let progress = now.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                currentHeight = height1 + (height2 - height1) * progress
                isRising = height2 > height1
                currentType = isRising ? .rising : .falling
                break
            }
        }
        
        // Convert upcoming tides - only HIGH and LOW tides, not NORMAL points
        let upcomingTides = sortedTides.compactMap { tide -> TidePrediction? in
            guard let timestamp = tide.timestamp,
                  let height = tide.height,
                  let type = tide.type else { return nil }
            
            // Skip NORMAL tides - we only want HIGH and LOW extremes
            guard type == "HIGH" || type == "LOW" else { return nil }
            
            let time = Date(timeIntervalSince1970: TimeInterval(timestamp))
            guard time > now else { return nil }
            
            let tideType: TidePrediction.TideType = type == "HIGH" ? .high : .low
            let willRise = type == "LOW" // After low tide, it rises
            
            return TidePrediction(
                time: time,
                height: height,
                type: tideType,
                isRising: willRise
            )
        }.prefix(4).map { $0 } // Get next 4 tides
        
        // Generate hourly predictions for chart (interpolate between tides) - FORWARD LOOKING
        var hourlyPredictions: [TidePrediction] = []
        let calendar = Calendar.current
        
        // Start from current hour and go forward 24 hours
        for hourOffset in 0..<24 {
            let hourTime = calendar.date(byAdding: .hour, value: hourOffset, to: now)!
            
            // Find surrounding tides for this hour
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
        
        // Get surf conditions (already fetched)
        let pleasurePointCondition = spotConditions.tideData != nil
            ? SurfCondition(
                quality: spotConditions.rating.value >= 4.5 ? .excellent :
                        spotConditions.rating.value >= 3.5 ? .good :
                        spotConditions.rating.value >= 2.5 ? .fair : .poor,
                tideHeight: currentHeight,
                time: now,
                reason: spotConditions.rating.text,
                spot: .pleasurePoint
            )
            : SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading conditions",
                spot: .pleasurePoint
            )
        
        // Get 26th Ave conditions
        let twentySixthId = AppConfig.surflineSpots.first(where: { $0.displayName == "26th Avenue" })?.id ?? ""
        let twentySixthConditions = surflineService.spotConditions[twentySixthId]
        let twentySixthCondition = twentySixthConditions != nil
            ? SurfCondition(
                quality: twentySixthConditions!.rating.value >= 4.5 ? .excellent :
                        twentySixthConditions!.rating.value >= 3.5 ? .good :
                        twentySixthConditions!.rating.value >= 2.5 ? .fair : .poor,
                tideHeight: currentHeight,
                time: now,
                reason: twentySixthConditions!.rating.text,
                spot: .twentySixthAve
            )
            : SurfCondition(
                quality: .fair,
                tideHeight: currentHeight,
                time: now,
                reason: "Loading conditions",
                spot: .twentySixthAve
            )
        
        
        return TideData(
            currentTide: TidePrediction(
                time: now,
                height: currentHeight,
                type: currentType,
                isRising: isRising
            ),
            nextTides: upcomingTides,
            hourlyPredictions: hourlyPredictions,
            pleasurePointCondition: pleasurePointCondition,
            twentySixthCondition: twentySixthCondition,
            waveData: nil,
            lastUpdated: now
        )
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if isLoading {
                ProgressView("Loading...")
                    .frame(width: 350, height: 400)
            } else if let data = tideData {
                // Compact tide header
                CompactTideHeader(tideData: data)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                
                // Compact tide chart
                if !data.hourlyPredictions.isEmpty {
                    EnhancedTideChart(predictions: data.hourlyPredictions)
                        .frame(height: 100)
                        .padding(.horizontal, 10)
                }
                
                // Compact tide pools indicator
                CompactTidePoolIndicator(tideData: data)
                    .padding(.horizontal, 10)
                
                // Compact surf spots
                VStack(spacing: 4) {
                    ForEach(AppConfig.surflineSpots.prefix(2), id: \.id) { spot in
                        if let conditions = surflineService.spotConditions[spot.id] {
                            CompactSpotCard(conditions: conditions)
                                .padding(.horizontal, 10)
                        }
                    }
                }
                
                Spacer()
            } else {
                Text("Failed to load")
                    .frame(width: 350, height: 400)
            }
        }
        .frame(width: 350, height: 400)
        .background(
            ZStack {
                // Semi-transparent gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.6),
                        Color(red: 0.1, green: 0.15, blue: 0.25).opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Material effect for blur
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.5))
            }
        )
        .task {
            // Initial fetch - using Surfline for everything now
            await surflineService.fetchAllSpotsData()
            
            // Convert Surfline tide data to TideData format
            let data = await convertSurflineTideData()
            
            await MainActor.run {
                self.tideData = data
                self.isLoading = false
            }
            
            // Refresh every 30 minutes
            while true {
                try? await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000)
                
                await surflineService.fetchAllSpotsData()
                let refreshData = await convertSurflineTideData()
                
                await MainActor.run {
                    self.tideData = refreshData
                }
            }
        }
    }
}

// Simple header for current tide info
struct CurrentTideHeader: View {
    let tideData: TideData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                    .font(.title2)
                
                Text("\(tideData.currentTide.isRising ? "Rising" : "Falling") Tide")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tideData.currentTide.height, specifier: "%.1f") ft")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }
            
            // Next tide info
            if let nextTide = tideData.nextTides.first {
                HStack {
                    Text("Next \(nextTide.type == .high ? "High" : "Low"):")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(nextTide.time.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("(\(nextTide.height, specifier: "%.1f") ft)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
            }
            
            // Tide pool alert if applicable
            if tideData.currentTide.shouldShowTidePoolAlert {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.purple)
                    Text(tideData.currentTide.tidePoolMessage ?? "Tide pools accessible!")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.2))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Compact Widget Views

struct CompactTideHeader: View {
    let tideData: TideData
    
    var body: some View {
        HStack(spacing: 12) {
            // Tide direction
            Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(
                    tideData.currentTide.isRising ? 
                    LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(tideData.currentTide.isRising ? "Rising" : "Falling") Tide")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if let nextTide = tideData.nextTides.first {
                    Text("Next \(nextTide.type == .high ? "High" : "Low"): \(nextTide.time.formatted(.dateTime.hour().minute()))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Current height
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(tideData.currentTide.height, specifier: "%.1f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(tideData.currentTide.height < 0 ? .purple : .cyan)
                Text("ft")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

struct CompactTidePoolIndicator: View {
    let tideData: TideData
    
    var body: some View {
        let conditions = TidePoolConditions.evaluate(from: tideData)
        
        HStack(spacing: 8) {
            Image(systemName: "circle.hexagongrid.circle.fill")
                .font(.caption)
                .foregroundColor(.cyan)
            
            Text("Tide Pools")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(conditions.condition.emoji)
                .font(.caption)
            
            Text(conditions.condition.text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(conditions.condition.color)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(conditions.condition.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}