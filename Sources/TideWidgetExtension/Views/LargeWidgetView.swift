import SwiftUI
import WidgetKit
import Charts

struct LargeWidgetView: View {
    let entry: TideEntry
    
    var body: some View {
        if let tideData = entry.tideData {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack {
                        Image(systemName: "water.waves")
                            .foregroundStyle(.cyan)
                        Text("mytides")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: tideData.lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Main content
                HStack(alignment: .top, spacing: 16) {
                    // Left - Current conditions
                    VStack(alignment: .leading, spacing: 12) {
                        // Current tide
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Now")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.1f", tideData.currentTide.height))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(tideGradient(for: tideData))
                                Text("ft")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            HStack {
                                Image(systemName: tideData.currentTide.isRising ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(tideData.currentTide.isRising ? .green : .orange)
                                Text(tideData.currentTide.isRising ? "Rising" : "Falling")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if let tidePoolMessage = tideData.currentTide.tidePoolMessage {
                                Text(tidePoolMessage)
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Featured spots
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Featured Spots")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                            
                            FeaturedSpotView(
                                spot: .pleasurePoint,
                                condition: tideData.pleasurePointCondition
                            )
                            
                            FeaturedSpotView(
                                spot: .twentySixthAve,
                                condition: tideData.twentySixthCondition
                            )
                        }
                    }
                    .frame(width: 160)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Right - Upcoming tides
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Tides")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(Array(tideData.nextTides.prefix(4).enumerated()), id: \.offset) { index, tide in
                            UpcomingTideRow(tide: tide)
                            if index < 3 {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
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
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

struct FeaturedSpotView: View {
    let spot: SurfSpot
    let condition: SurfCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(spot.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(condition.quality.emoji)
                    .font(.caption)
            }
            
            Text(condition.reason)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(qualityColor(condition.quality).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(qualityColor(condition.quality).opacity(0.3), lineWidth: 1)
                )
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

struct UpcomingTideRow: View {
    let tide: TidePrediction
    
    var body: some View {
        HStack {
            Image(systemName: tide.type == .high ? "arrow.up.to.line" : "arrow.down.to.line")
                .font(.caption)
                .foregroundColor(tide.type == .high ? .blue : .orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tide.type == .high ? "High" : "Low")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Text(timeFormatter.string(from: tide.time))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("\(tide.height, specifier: "%.1f") ft")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(tide.height < 0 ? .purple : .cyan)
        }
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}