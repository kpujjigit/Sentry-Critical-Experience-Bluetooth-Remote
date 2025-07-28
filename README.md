# Bluetooth Remote - Sentry iOS Demo App

A demonstration iOS app that simulates a Bluetooth audio device remote control, featuring comprehensive [Sentry](https://sentry.io) integration for error monitoring, performance tracking, and user experience analytics.

## 🎯 Purpose

This app showcases how Sentry's iOS SDK can be used to:
- **Monitor critical user journeys** in mobile applications
- **Track performance metrics** for key user interactions
- **Capture comprehensive error context** for faster debugging
- **Build actionable dashboards** from span-based metrics
- **Demonstrate mobile-specific features** like Session Replay and Mobile Vitals

## ✨ Features

### Core App Functionality
- **Device Discovery & Connection**: Simulated Bluetooth device scanning and pairing
- **Audio Playback Control**: Play, pause, skip, volume, and EQ controls
- **Playlist Management**: Track selection, shuffle, and repeat modes
- **Sonos-Inspired UI**: Clean, modern interface based on Sonos mobile app design

### Sentry Integration Features
- **Performance Monitoring**: Automatic and custom transaction tracking
- **Error Monitoring**: Comprehensive error capture with rich context
- **Session Replay**: Visual replay of user sessions (mobile)
- **Mobile Vitals**: App start time, slow/frozen frames tracking
- **Custom Metrics**: Span-based metrics for building dashboards
- **Breadcrumbs**: Detailed user action trails
- **Profiling**: Performance profiling for optimization
- **Release Health**: Session tracking and crash-free rates

## 🚀 Quick Start

### Prerequisites
- Xcode 15.0+ 
- iOS 14.0+ target
- Valid Sentry project and DSN

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd "CX - BT Remote"
   ```

2. **Configure Sentry**:
   - Open `BluetoothRemote/AppDelegate.swift`
   - Replace the placeholder DSN with your actual Sentry project DSN:
   ```swift
   options.dsn = "https://your-actual-dsn@o0.ingest.sentry.io/0"
   ```

3. **Build and Run**:
   - Open `BluetoothRemote.xcodeproj` in Xcode
   - Select a simulator or device target
   - Build and run the project (⌘R)
   
   > **⚠️ Simulator Compatibility Note**: If you experience a black screen when running in Xcode simulator, try using iOS 18.5 or higher simulator. Older iOS versions may have compatibility issues with the SwiftUI setup.

## 📊 Sentry Configuration

### Comprehensive SDK Setup

The app is configured with Sentry's most comprehensive instrumentation:

```swift
SentrySDK.start { options in
    options.dsn = "YOUR_DSN_HERE"
    
    // Performance Monitoring
    options.tracesSampleRate = 1.0 // 100% for demo
    options.enableAutoPerformanceTracing = true
    
    // Automatic Instrumentation
    options.enableUIViewControllerTracing = true
    options.enableNetworkTracking = true
    options.enableFileIOTracing = true
    options.enableUserInteractionTracing = true
    
    // Mobile Features
    options.experimental.sessionReplay.sessionSampleRate = 1.0
    options.configureProfiling = { $0.sessionSampleRate = 1.0 }
    
    // Enhanced Context
    options.sendDefaultPii = true
    options.attachStacktrace = true
    options.maxBreadcrumbs = 150
}
```

### Key Instrumented Operations

| Operation | Span Name | Tags | Purpose |
|-----------|-----------|------|---------|
| Device Connection | `Connect to Bluetooth Device` | device_name, device_type, signal_strength | Track connection success/failure rates |
| Audio Playback | `Audio Playback` | track_title, track_artist, device_name | Monitor playback reliability |
| Track Navigation | `Skip to Next Track` | track_index, skip_result | Measure user engagement patterns |
| Volume Adjustment | `audio.volume` | volume_level | Track user interaction frequency |
| EQ Changes | `Apply EQ Preset` | preset_name, bass_setting, treble_setting | Monitor feature usage |

## 🎮 Demo Scenarios

This app simulates **two critical user workflows** identified through research of real-world Bluetooth audio control apps:

### 1. **Device Discovery and Pairing Flow** 🔍
*Critical Success Factor: Seamless device identification and connection*

**User Journey:**
- Tap "Devices" tab → Scan for available Bluetooth speakers
- Review device list with signal strength and battery info
- Select target device (e.g., "JBL Flip 5" or "Sony SRS-XB43") 
- Monitor connection progress and handle failures gracefully

**Sentry Metrics Captured:**
- Device scan duration and success rates
- Connection attempt outcomes by device type
- User abandonment points during pairing
- Error context for failed connections

**Technical Implementation:**
- `bt.scan` transaction for device discovery
- `bt.connection` transaction with detailed timing
- Custom metrics: `bluetooth.connection.success/failure`
- Success criteria: Connection latency < 3 seconds

### 2. **Active Audio Control and Session Management** 🎵  
*Critical Success Factor: Responsive controls and session continuity*

**User Journey:**
- Navigate to "Now Playing" → Control active audio session
- Test core controls: play/pause, skip tracks, volume adjustment
- Experiment with EQ settings and audio preferences  
- Switch between playlists and maintain session state

**Sentry Metrics Captured:**
- User interaction response times (< 50ms UI blocking requirement)
- Audio control success/failure rates
- Session duration and engagement patterns
- Feature usage analytics (EQ presets, skip frequency)

**Technical Implementation:**
- `ui.action.remoteControl` spans for all user interactions
- `bt.write.command` spans (< 120ms RTT requirement)
- `device.response` child spans (ACK < 250ms requirement)
- `ui.state.render` spans (< 16ms frame requirement)

### 3. **Error Recovery and Edge Cases** ⚠️
- Simulate connection timeouts and recovery
- Test app crash scenarios with automatic restart
- Handle audio playback interruptions

## 📊 Technical Instrumentation

### BLE Command Flow (Following Bluetooth Stack Layers)
```
User Gesture → Mobile App (Swift/Sentry) → BLE Stack → Device ACK → UI Update
     |              |                         |            |         |
 < 50ms      ui.action.remoteControl    bt.write.command  device.response  ui.state.render
                                            < 120ms         < 250ms      < 16ms
```

### Custom Span Metrics
| Span Operation | Success Criteria | Failure Signals | Business Value |
|----------------|------------------|------------------|----------------|
| `ui.action.remoteControl` | < 50ms blocking | ANR, frame drops | User retention |
| `bt.write.command` | < 120ms RTT | timeout, retry | Device compatibility |
| `device.response` | ACK < 250ms | no ACK, error code | Connection quality |
| `ui.state.render` | < 16ms frame | stale UI, mismatch | Perceived performance |

### Dashboard Metrics Available
- **Connection Success Rate**: `bluetooth.connection.success` vs `bluetooth.connection.failure`
- **Command Latency**: `command.latency_ms` distribution by device type
- **UI Responsiveness**: `ui.action.latency_ms` by control type
- **Feature Usage**: `eq.preset.applied`, `track.skip` counters
- **Session Health**: Connection duration, error rates by signal strength

## 📈 Building Dashboards

### Suggested Queries for Sentry Dashboards

#### Connection Success Rate
```sql
SELECT 
    count_if(tags[connection_result] = 'success') / count() as success_rate
FROM transactions
WHERE transaction = 'Connect to Bluetooth Device'
```

#### Audio Playback Performance
```sql
SELECT 
    avg(duration) as avg_playback_start_time,
    p95(duration) as p95_playback_start_time
FROM transactions
WHERE transaction = 'Audio Playback'
```

#### User Engagement Metrics
```sql
SELECT 
    tags[device_type],
    count() as connection_attempts,
    avg(duration) as avg_connection_time
FROM transactions
WHERE transaction LIKE '%bluetooth%'
GROUP BY tags[device_type]
```

#### Feature Usage Tracking
```sql
SELECT 
    tags[preset_name],
    count() as usage_count
FROM transactions
WHERE transaction = 'Apply EQ Preset'
GROUP BY tags[preset_name]
ORDER BY usage_count DESC
```

## 🔧 Advanced Configuration

### Custom Error Context

The app automatically enriches errors with contextual information:

```swift
scope.setContext(key: "app_state", value: [
    "connected_device": bluetoothService.connectedDevice?.name ?? "None",
    "current_track": audioPlayer.currentTrack?.title ?? "None",
    "playback_state": audioPlayer.playbackState.rawValue,
    "volume": audioPlayer.audioSettings.volume
])
```

### Performance Profiling

Enable continuous profiling for deeper performance insights:

```swift
options.configureProfiling = { profilingOptions in
    profilingOptions.sessionSampleRate = 1.0
    profilingOptions.lifecycle = .trace
}
```

### Session Replay Configuration

Capture visual user sessions for debugging:

```swift
options.experimental.sessionReplay.sessionSampleRate = 1.0
options.experimental.sessionReplay.errorSampleRate = 1.0
```

## 🎯 Key Demo Talking Points

### For Sales/Marketing Teams
- **"Zero-configuration monitoring"** - Show automatic instrumentation
- **"Complete user journey visibility"** - Demonstrate breadcrumb trails
- **"Mobile-first approach"** - Highlight Session Replay and Mobile Vitals
- **"Actionable insights"** - Build dashboards from collected metrics

### For Engineering Teams
- **"Comprehensive span tracking"** - Show custom instrumentation
- **"Rich error context"** - Demonstrate debugging capabilities
- **"Performance optimization"** - Use profiling data for improvements
- **"Release health monitoring"** - Track app stability over time

### For Product Teams
- **"User behavior insights"** - Show engagement metrics
- **"Feature adoption tracking"** - Monitor EQ preset usage
- **"Quality metrics"** - Connection success rates and reliability
- **"User experience optimization"** - Identify pain points in journeys

## 📱 App Structure

```
BluetoothRemote/
├── AppDelegate.swift          # Sentry configuration
├── SceneDelegate.swift        # App lifecycle tracking
├── ContentView.swift          # Main tab interface
├── Models/
│   └── BluetoothDevice.swift  # Data models
├── Services/
│   ├── BluetoothService.swift # Device management with tracing
│   └── AudioPlayerService.swift # Audio controls with metrics
└── Views/
    ├── NowPlayingView.swift   # Audio player interface
    ├── PlaylistView.swift     # Track selection
    └── SettingsView.swift     # Demo controls and settings
```

## 🛠️ Troubleshooting

### Common Issues

1. **No Sentry Data Appearing**:
   - Verify DSN is correctly set in `AppDelegate.swift`
   - Check network connectivity
   - Ensure debug mode is enabled: `options.debug = true`

2. **Performance Data Missing**:
   - Confirm `tracesSampleRate = 1.0` for testing
   - Check that automatic instrumentation is enabled
   - Verify transactions are properly finished

3. **Simulator vs Device**:
   - Some features (like Session Replay) work better on physical devices
   - Bluetooth simulation is more realistic on device

### Debug Mode

Enable verbose logging for troubleshooting:

```swift
options.debug = true
options.logLevel = .debug
```

## 📚 References

- [Sentry iOS SDK Documentation](https://docs.sentry.io/platforms/apple/guides/ios/)
- [Sentry Performance Monitoring](https://docs.sentry.io/platforms/apple/guides/ios/tracing/)
- [Sentry Session Replay](https://docs.sentry.io/platforms/apple/guides/ios/session-replay/)
- [Mobile Vitals Guide](https://docs.sentry.io/product/insights/mobile-vitals/)

## 📄 License

This project is created for demonstration purposes. The code structure and Sentry integration patterns can be adapted for real-world applications.

---

**Note**: This is a demonstration app with simulated Bluetooth functionality. It does not actually connect to real Bluetooth devices. The focus is on showcasing Sentry's monitoring and analytics capabilities in a realistic user experience context. 