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
   cd "CX - BT Remote"
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