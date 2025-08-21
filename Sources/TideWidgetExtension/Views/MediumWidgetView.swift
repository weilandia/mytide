import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: TideEntry
    
    var body: some View {
        if let tideData = entry.tideData {
            HStack(spacing: 16) {
                // Left side - Current conditions
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Image(systemName: "water.waves")
                            .foregroundStyle(.cyan)
                        Text("mytides")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Current tide
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Tide")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", tideData.currentTide.height))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(tideGradient(for: tideData))
                            Text("ft")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.body)
                                .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                        }
                        
                        if let tidePoolMessage = tideData.currentTide.tidePoolMessage {
                            Text(tidePoolMessage)
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.yellow.opacity(0.2)))
                        }
                    }
                
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Right side - Next tides and surf spots
                VStack(alignment: .leading, spacing: 8) {
                    // Next tides
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Tides")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        ForEach(Array(tideData.nextTides.prefix(3).enumerated()), id: \.offset) { index, tide in
                            HStack {
                                Image(systemName: tide.type == .high ? "arrow.up.to.line" : "arrow.down.to.line")
                                    .font(.caption2)
                                    .foregroundColor(tide.type == .high ? .blue : .orange)
                                Text("\(tide.type == .high ? "H" : "L")")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                Text(tide.time.formatted(.dateTime.hour().minute()))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(tide.height, specifier: "%.1f")ft")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(tide.height < 0 ? .purple : .cyan)
                            }
                        }
                    }
                    
                    // Surf spots if available
                    if let spotConditions = entry.spotConditions {
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Surf Spots")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(AppConfig.surflineSpots.prefix(2), id: \.id) { spot in
                                if let conditions = spotConditions[spot.id] {
                                    HStack {
                                        Text(spot.displayName)
                                            .font(.caption2)
                                            .lineLimit(1)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(0..<Int(conditions.rating.value)) { _ in
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func tideGradient(for tideData: TideData) -> LinearGradient {
        if tideData.currentTide.isNegative {
            return LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct SpotConditionRow: View {
    let spotName: String
    let condition: SurfCondition
    let isHighlighted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(spotName)
                    .font(.caption)
                    .fontWeight(isHighlighted ? .semibold : .regular)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(condition.quality.emoji)
                    .font(.caption)
                Text(condition.quality.displayName)
                    .font(.caption2)
                    .foregroundColor(qualityColor(condition.quality))
            }
            
            if isHighlighted {
                Text(condition.reason)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(isHighlighted ? 0.1 : 0.05))
        )
    }
    
    func qualityColor(_ quality: SurfQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}