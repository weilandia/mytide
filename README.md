# mytides 🌊

![mytides Widget Screenshot](screenshot-placeholder.png)

## The DIY AI Era

We're living in an incredible moment where AI can help us build exactly what we want. This project represents that ethos perfectly - it's a custom macOS widget I wanted for checking Santa Cruz tide and surf conditions, built with AI assistance in a single afternoon.

**This isn't meant to be a general-purpose app.** It's specifically configured for my favorite surf spots in Santa Cruz. But that's the beauty of the DIY AI era - you can fork this and make it yours in minutes.

## What It Does

- 📊 **Real-time tide data** from Surfline API
- 🏄 **Surf conditions** for Pleasure Point and 26th Avenue
- 🌊 **Tide pool alerts** when conditions are perfect (negative tides)
- 📈 **24-hour forward-looking tide chart**
- ⭐ **Surf spot ratings** with live conditions
- 🔄 **Auto-updates** every 30 minutes

## Fork & Build Your Own

### Prerequisites

1. **macOS 14.0+** (Sonoma or newer)
2. **Xcode 15+** installed from the App Store
3. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

### Quick Start

1. **Fork & Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/mytides.git
   cd mytides
   ```

2. **Configure Your Spots**
   
   Edit `Sources/TideWidgetExtension/Configuration/AppConfig.swift`:
   ```swift
   static let surflineSpots = [
       SurflineSpot(
           id: "YOUR_SPOT_ID",  // Get from Surfline URL
           name: "Your Spot",
           displayName: "Display Name"
       )
   ]
   ```
   
   To find your spot ID:
   - Go to surfline.com
   - Navigate to your spot
   - Copy the ID from the URL: `surfline.com/surf-report/spot-name/SPOT_ID_HERE`

3. **Build the Widget**

   **Option A: Command Line**
   ```bash
   swift build -c release
   ```

   **Option B: Xcode (Recommended)**
   - Open `mytides.xcodeproj` in Xcode
   - Select the widget target
   - Click ▶️ Run

4. **Install the Widget**
   - Right-click on your desktop
   - Select "Edit Widgets"
   - Search for "mytides"
   - Click + to add it
   - Choose your size (Small/Medium/Large)

## Customization Guide

### Change Locations

The app is hardcoded for Santa Cruz spots. To adapt for your area:

1. **Update Spot Configuration** in `AppConfig.swift`
2. **Modify Display Names** throughout the views
3. **Adjust Tide Pool Logic** in `TidePoolConditions.swift` for your local conditions

### Adjust Update Frequency

In `TideWidget.swift`, modify the timeline refresh:
```swift
// Change from 30 minutes to your preference
.after(Calendar.current.date(byAdding: .hour, value: 6, to: currentDate)!)
```

### Widget Sizes

- **Small**: Current tide + next high/low
- **Medium**: Tide info + surf conditions
- **Large**: Full chart + all conditions

## Architecture

```
Sources/TideWidgetExtension/
├── Configuration/
│   └── AppConfig.swift         # Spot configuration
├── Models/
│   ├── TideData.swift         # Core data models
│   └── SurfSpot.swift         # Spot definitions
├── Services/
│   └── EnhancedSurflineService.swift  # Surfline API
├── Views/
│   ├── SmallWidgetView.swift  # Widget layouts
│   ├── MediumWidgetView.swift
│   └── LargeWidgetView.swift
└── TideWidget.swift           # Widget entry point
```

## Known Issues & Limitations

- **Surfline API**: No official API, uses public endpoints that may change
- **Build Issues**: If you get `dyld` errors, reinstall Xcode Command Line Tools
- **Widget Not Appearing**: Restart NotificationCenter: `killall NotificationCenter`

## The Philosophy

This project embodies the DIY spirit of our AI-assisted era:

1. **Built for one person**: Me. It does exactly what I need.
2. **Easily forkable**: You can make it yours in minutes.
3. **AI-assisted**: Built with Claude in a few hours.
4. **No bloat**: No analytics, no accounts, no BS.
5. **Local first**: Your data stays on your machine.

## Contributing

This is a personal project, but if you fork it and make something cool, I'd love to see it! Feel free to share your adaptations.

## License

MIT - Do whatever you want with it. That's the point.

## Acknowledgments

- Built with Claude (Anthropic)
- Tide data from Surfline (unofficial)
- Inspired by the need to know when to paddle out 🏄‍♂️

---

*"The best software is the software you build for yourself."*