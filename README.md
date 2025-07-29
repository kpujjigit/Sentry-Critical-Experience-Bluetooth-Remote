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
- **Session Replay**: Visual replay of user sessions with privacy-focused redaction
- **Mobile Vitals**: App start time, slow/frozen frames tracking, screen load performance
- **Mobile Performance Insights**: Complete iOS performance monitoring suite
- **Network Request Tracking**: BLE command performance and failure analysis
- **Session Health Monitoring**: User session quality and engagement metrics
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
    options.enableTimeToFullDisplayTracing = true // TTFD automatic tracking
    
    // Mobile Session Replay
    options.experimental.sessionReplay.sessionSampleRate = 1.0
    options.experimental.sessionReplay.onErrorSampleRate = 1.0
    options.experimental.sessionReplay.maskAllText = true
    options.experimental.sessionReplay.maskAllImages = true
    
    // Profiling
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

### App Launch Performance Tracking (TTID/TTFD)

The app implements comprehensive app launch performance monitoring with both **Time to Initial Display (TTID)** and **Time to Full Display (TTFD)** tracking:

```swift
// TTID - When UI becomes visible
let ttidSpan = appLaunchSpan.startChild(operation: "app.launch.ttid", description: "Time to Initial Display")
// ... UI setup ...
ttidSpan.setTag(value: "completed", key: "ttid_status")
ttidSpan.finish()

// TTFD - When app becomes fully interactive
let ttfdSpan = appLaunchSpan.startChild(operation: "app.launch.ttfd", description: "Time to Full Display")
// ... full initialization ...
ttfdSpan.setTag(value: "interactive", key: "ttfd_status")
ttfdSpan.finish()

// Report TTFD to Sentry for enableTimeToFullDisplayTracking compliance
SentrySDK.reportFullyDisplayed()
```

**TTFD Compliance Strategy:**
- **Custom Spans**: Detailed timing with business context and tags
- **Sentry Native Call**: `SentrySDK.reportFullyDisplayed()` for automatic SDK integration
- **Dual Approach**: Comprehensive tracking + native Sentry Mobile Vitals compatibility

### Custom Span Metrics
| Span Operation | Success Criteria | Failure Signals | Business Value |
|----------------|------------------|------------------|----------------|
| `app.launch.ttid` | < 1000ms | slow UI render | First impression |
| `app.launch.ttfd` | < 2000ms | delayed interactivity | User engagement |
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

#### App Launch Performance (TTID/TTFD)
```sql
-- Time to Initial Display metrics
SELECT 
    avg(duration) as avg_ttid_ms,
    p95(duration) as p95_ttid_ms
FROM spans
WHERE op = 'app.launch.ttid'

-- Time to Full Display metrics  
SELECT 
    avg(duration) as avg_ttfd_ms,
    p95(duration) as p95_ttfd_ms
FROM spans
WHERE op = 'app.launch.ttfd'
```

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

Capture visual user sessions for debugging with privacy protection:

```swift
// Session Replay with Privacy Controls
options.experimental.sessionReplay.sessionSampleRate = 1.0 // 100% for demo
options.experimental.sessionReplay.onErrorSampleRate = 1.0 // Capture on all errors
options.experimental.sessionReplay.maskAllText = true // Redact all text content
options.experimental.sessionReplay.maskAllImages = true // Redact all images
```

**Privacy Features:**
- All text content is automatically masked with asterisks
- All images are redacted with colored blocks
- User input is never captured in plain text
- View hierarchy structure is preserved for debugging context

**How to View Session Replays:**
1. Navigate to your Sentry project → **Replays** section
2. Click on any session to watch the video playback
3. Use the timeline to jump to specific events or errors
4. View synchronized network requests, breadcrumbs, and console logs
5. Click error links to see issues with full session context

Each replay captures:
- User taps and gestures
- Screen transitions and navigation
- Background/foreground state changes
- Device orientation changes
- Network requests and responses
- All errors with visual context

### Mobile Performance Insights Configuration

Comprehensive iOS performance monitoring following [Sentry's Mobile Performance documentation](https://docs.sentry.io/product/insights/mobile/):

```swift
// Mobile Vitals & Performance Insights
options.enableAppLaunchProfiling = true // App start performance tracking
options.enableFramesTracking = true // Slow/frozen frame detection
options.enableAppHangTracking = true // ANR/hang detection
options.appHangTimeoutInterval = 2.0 // Detect hangs > 2 seconds
options.enableAutoSessionTracking = true // Session health monitoring

// Network Performance Monitoring
options.enableNetworkBreadcrumbs = true // Network request breadcrumbs
options.enableCaptureFailedRequests = true // Failed network requests

// iOS-specific Performance Features (with proper availability checks)
if #available(iOS 13.0, *) {
    options.enableMetricKit = true // iOS MetricKit integration (iOS 13.0+)
}
if #available(iOS 14.0, *) {
    options.enableWatchdogTerminationTracking = true // Track app terminations (iOS 14.0+)
}
```

**Key Mobile Performance Metrics Captured:**

1. **App Launch Performance**:
   - Cold start times with `app.launch` transactions
   - Time to Initial Display (TTID) - when UI becomes visible with `app.launch.ttid` spans
   - Time to Full Display (TTFD) - when app becomes fully interactive with `app.launch.ttfd` spans
   - **TTFD Compliance**: Uses both custom tracking spans AND `SentrySDK.reportFullyDisplayed()` for full Sentry compatibility
   - Launch success/failure rates

2. **Screen Performance**:
   - Screen load times (`screen.load` operations)
   - UI interaction response times (`ui.interaction` spans)
   - Frame rendering performance (slow/frozen frame detection)
   - Navigation performance between screens

3. **Network-like Performance** (BLE Commands):
   - Command request/response timing (`bt.write.command` → `device.response`)
   - Connection quality metrics (signal strength, battery impact)
   - Request success/failure rates with detailed error context
   - Network-style performance categorization for dashboard compatibility

4. **Session Health Metrics**:
   - Session duration and user engagement patterns
   - Device characteristics (CPU cores, memory, iOS version)
   - Background/foreground state transitions
   - App termination and crash tracking

5. **Mobile Vitals Integration**:
   - Automatic frame performance tracking
   - App hang detection (ANR monitoring)
   - Memory pressure monitoring
   - iOS MetricKit system metrics integration

**Viewing Mobile Performance Data:**
1. Navigate to your Sentry project → **Insights** → **Mobile Performance**
2. View **Mobile Vitals** for app start times and frame performance
3. Check **Network Requests** for BLE command performance analysis
4. Monitor **Session Health** for user engagement and app stability metrics
5. Use **Profiling** data for code-level performance optimization

## 🎯 Key Demo Talking Points

### For Sales/Marketing Teams
- **"Zero-configuration monitoring"** - Show automatic instrumentation
- **"Visual debugging with Session Replay"** - Watch actual user sessions leading to errors
- **"Complete user journey visibility"** - Demonstrate breadcrumb trails and video context
- **"Mobile-first approach"** - Highlight Session Replay and Mobile Vitals
- **"Privacy-by-design"** - Show automatic text and image redaction
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

4. **MetricKit Issues**:
   - If the app crashes during startup with MetricKit enabled, disable it temporarily:
   ```swift
   // Temporarily disable MetricKit if causing issues
   // options.enableMetricKit = true
   ```
   - MetricKit requires iOS 13.0+ and may have compatibility issues with certain simulators
   - Check Console.app for MetricKit-related error messages

### Debug Mode

Enable verbose logging for troubleshooting:

```swift
options.debug = true
options.logLevel = .debug
```

### iOS Version Compatibility

If you encounter issues with specific Sentry features, ensure your iOS version meets the requirements:
- **iOS 14.0+** for general functionality and Session Replay
- **iOS 13.0+** for MetricKit integration 
- **iOS 14.0+** for WatchdogTerminationTracking
- **iOS 18.5+** recommended for optimal SwiftUI compatibility in simulator

## 📚 References

- [Sentry iOS SDK Documentation](https://docs.sentry.io/platforms/apple/guides/ios/)
- [Sentry Performance Monitoring](https://docs.sentry.io/platforms/apple/guides/ios/tracing/)
- [Sentry Session Replay](https://docs.sentry.io/platforms/apple/guides/ios/session-replay/)
- [Mobile Vitals Guide](https://docs.sentry.io/product/insights/mobile-vitals/)

## 📄 License

This project is created for demonstration purposes. The code structure and Sentry integration patterns can be adapted for real-world applications.

---

**Note**: This is a demonstration app with simulated Bluetooth functionality. It does not actually connect to real Bluetooth devices. The focus is on showcasing Sentry's monitoring and analytics capabilities in a realistic user experience context. 

## 🎭 Demo Performance Issues (For Sentry Dashboard Testing)

### 🚨 Artificially Poor Performance Scenarios

To demonstrate how Sentry captures and visualizes performance issues, the app includes subtle performance problems for specific devices. **These issues are designed to be discovered through metrics analysis rather than obvious indicators.**

#### **Scenario 1: Connection Success Rate Below 85%**
- **Target Device:** "Bedroom Move" (Portable speaker)
  - **Success Rate:** 40% (Will fail 6 out of 10 attempts)
  - **Discovery Method:** Low success rate visible in connection dashboards

- **Secondary Device:** "Basement Sub" (Subwoofer)
  - **Success Rate:** 70% (Will fail 3 out of 10 attempts)  
  - **Discovery Method:** Higher failure rate compared to other devices

#### **Scenario 2: Laggy Audio Controls**
- **Target Devices:** "Basement Sub" & "Kitchen One"
- **Affected Controls:**
  - **Skip Next:** 150ms delay (vs 20ms normal)
  - **Skip Previous:** 180ms delay (vs 25ms normal)
  - **Shuffle Playlist:** 250ms delay (vs 30ms normal)
- **Discovery Method:** High P95 latency times in performance dashboards

#### **Expected Dashboard Results:**
1. **Connection Success Rate:** Will show ~75% overall (below 85% threshold)
2. **Audio Control P95 Latency:** Will show >100ms for problematic devices
3. **Device Breakdown:** Clear performance differences by device name

### 📊 Demo Script for Presentations

**Step 1: Show Baseline Performance**
1. Connect to "Living Room Arc" or "Office Era 100" 
2. Use audio controls → Should show normal performance (~20-30ms)
3. **Discovery:** "Notice how responsive these controls feel"

**Step 2: Demonstrate Connection Issues** 
1. Try connecting to "Bedroom Move" multiple times
2. **Discovery:** "Hmm, this device seems to fail a lot"
3. Show Sentry dashboard → "Let's check our metrics to see what's happening"
4. Point out success rate drops below 85%

**Step 3: Demonstrate Laggy Controls**
1. Connect to "Basement Sub" 
2. Use skip/shuffle controls → "These controls feel sluggish"
3. **Discovery:** "Let's investigate the performance data"
4. Show Sentry dashboard → P95 latency >150ms for these devices

**Step 4: Root Cause Analysis**
1. Open Trace Explorer → Filter by `device_name:"Basement Sub"`
2. Show span durations → "Look at these timing differences"
3. **Discovery:** "We can see certain devices consistently perform worse"
4. Correlate with device metadata and usage patterns

### 🎯 Sentry Query Examples for Demo

```sql
-- Discover connection issues by examining success rates
SELECT 
    tags[device_name],
    count_if(tags[connection_result] = 'failure') / count() * 100 as failure_rate
FROM spans
WHERE span.op = 'bt.connection'
GROUP BY tags[device_name]
ORDER BY failure_rate DESC

-- Investigate audio control performance by device  
SELECT 
    tags[device_name],
    tags[control_type],
    percentile(span.duration, 0.95) as p95_latency_ms,
    avg(span.duration) as avg_latency_ms
FROM spans  
WHERE span.op = 'ui.action.remoteControl'
GROUP BY tags[device_name], tags[control_type]
ORDER BY p95_latency_ms DESC
```

### 🔧 Reverting Demo Issues

To return to normal performance, modify these values in the code:

**BluetoothService.swift** (Line ~90):
```swift
// Change back to normal 95% success rate for all devices
let willSucceed = Double.random(in: 0...1) > 0.05
```

**AudioPlayerService.swift** (Lines ~210, ~260, ~480):
```swift  
// Remove device-specific delays, set all to normal:
artificialDelay = 0.02 // Normal delay for all devices
```

### 💡 **Key Demo Philosophy**

The performance issues are **subtle and realistic** - developers discover problems through:
- **Metrics Analysis:** High latency, low success rates
- **Comparative Data:** Some devices perform worse than others  
- **User Experience:** Noticeable lag during actual usage
- **Trend Investigation:** Patterns emerge through dashboard analysis

**No obvious "demo" or "artificial" tags** - issues are discovered the same way real performance problems would be found in production. 