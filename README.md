# Bluetooth Remote - Sentry iOS Demo App

A SwiftUI demo application that simulates a Bluetooth audio remote and sends rich telemetry to Sentry for error, performance, and user-experience monitoring.

## Purpose

Demonstrate how to instrument critical mobile workflows with span operations and attributes that power dashboards and alerts in Sentry.

## Key Span Operations

- bt.scan
- bt.connection
- bt.write.command
- device.response
- ui.action.user
- ui.state.render
- ui.screen.load

Important attributes and data:
- Tags: device_name, device_type, connection_result, control_type, screen_name, load_status, user_action
- Data (span.data.*): devices_found, scan_duration_ms, signal_strength, connection_time_ms, write_latency_ms, ack_latency_ms, total_latency_ms, render_time_ms, volume_level

## Problem Device for Demos

The device named "Basement Sub" is intentionally slower and less reliable in the simulator. You will see elevated percentiles and higher failure rates for this device across connection and command metrics. Use this to demonstrate how Sentry helps you detect, visualize, and triage problems in critical workflows.

## Local Setup

1. Prerequisites
   - Xcode 15+
   - iOS Simulator 17+ (18.5 recommended)
   - A Sentry project DSN

2. Clone and open
   ```bash
   git clone <repository-url>
   cd <repo-folder>   # e.g., cd "CX - BT Remote"
   open BluetoothRemote.xcodeproj
   ```

3. Configure Sentry DSN (optional)
   - Edit `BluetoothRemote/AppDelegate.swift` and set `options.dsn` to your DSN, or
   - Provide environment variables when launching from Xcode Scheme: `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE`.

4. Build and run in Simulator
   - Select an iPhone simulator (iOS 18.5 recommended)
   - Run the app from Xcode

## Generate Demo Data (Simulator)

1. In the app, open the Settings tab.
2. In "Sentry Dashboard Data Simulator":
   - Choose session count (150 recommended)
   - Start Simulation

The simulator emits:
- bt.scan with scan_status and devices_found
- bt.connection with connection_result and connection_time_ms
- bt.write.command with write_latency_ms and total_latency_ms
- device.response with ack_latency_ms
- ui.action.user for play/pause/next/prev/volume (volume has span.data.volume_level) and playlist.shuffle
- ui.screen.load per screen with load_status and load_time_ms

Tip: Filter by `device_name:"Basement Sub"` to highlight problematic behavior.

## Notes on Queries

- Use tags.* for categorical values and span.data.* for numbers. Examples:
  - span.data.devices_found, span.data.signal_strength
  - span.data.write_latency_ms, span.data.ack_latency_ms, span.data.volume_level
- Track selection is `user_action:track_select`.

## Dashboard Metric Ideas

- Command Latency (p95)
  - What: How long commands take end-to-end
  - Query: `span.op:bt.write.command` → p95(span.duration) grouped by `tags.device_name`
  - Tip: Compare `device_name:"Basement Sub"` vs others

- ACK Response Latency (p95)
  - What: Device acknowledgment times
  - Query: `span.op:device.response` → p95(span.duration) grouped by `tags.device_type`

- Connection Success Rate
  - What: Reliability of device connections
  - Query: `span.op:bt.connection` → count_if(tags.connection_result:success) / count()
  - Group by: `tags.device_name`

- UI Control Responsiveness
  - What: Interaction responsiveness (play/pause/next/prev/volume)
  - Query: `span.op:ui.action.user` → max(span.duration), filter by `tags.control_type`
  - Examples: `tags.control_type:"audio.control.playpause"`, `"audio.control.next"`

- Screen Load Performance
  - What: How fast screens load
  - Query: `span.op:ui.screen.load` → p75(span.data.load_time_ms) grouped by `tags.screen_name`

- Volume Level Distribution
  - What: Typical volume levels used
  - Query: `span.op:ui.action.user` and `tags.control_type:"audio.volume.adjust"` → avg(span.data.volume_level)

- Command Failure Rate
  - What: Reliability of BLE commands
  - Query: `span.op:bt.write.command` → count_if(tags.command_status:failed) / count()
  - Group by: `tags.device_name`

## What’s Included

- BLE-like command/ACK spans and metrics
- Screen loads and UI control interactions
- Scan behavior including success, partial, and timeout cases
- Clear outlier device (Basement Sub) to showcase alerts and dashboards

## Troubleshooting

- If you see a blank screen in older simulators, prefer iOS 18.5 or newer.
- Confirm the DSN is configured and that the simulator has internet access.

## License

Demo project for showcasing Sentry capabilities. Adapt freely for your use cases. 