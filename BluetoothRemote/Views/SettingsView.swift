import SwiftUI
import Sentry

struct SettingsView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @EnvironmentObject var bluetoothService: BluetoothService
    @State private var showingCrashAlert = false
    @State private var showingErrorAlert = false
    @State private var showingSentryDemo = false
    @State private var isLoggingVerbose = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Sentry Data Simulation
                    SentryDataSimulatorView(
                        bluetoothService: bluetoothService,
                        audioPlayer: audioPlayer
                    )
                    
                    // Sentry Demo Features
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sentry Demo Features")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Button("Trigger Demo Error") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "trigger_demo_error",
                                screen: "SettingsView"
                            )
                            SentrySDK.addBreadcrumb(Breadcrumb(
                                level: .warning,
                                category: "sentry.demo"
                            ))
                            let error = NSError(domain: "DemoApp", code: 100, userInfo: [NSLocalizedDescriptionKey: "This is a simulated error from the Bluetooth Remote app."])
                            SentrySDK.capture(error: error) { scope in
                                scope.setTag(value: "user_action", key: "error_source")
                                scope.setContext(value: [
                                    "connected_device": bluetoothService.connectedDevice?.name ?? "None",
                                    "current_track": audioPlayer.currentTrack?.title ?? "None",
                                    "playback_state": audioPlayer.playbackState.rawValue,
                                    "volume": audioPlayer.audioSettings.volume,
                                    "playlist_size": audioPlayer.currentPlaylist.count
                                ], key: "app_state")
                            }
                            showingErrorAlert = true
                            span?.finish()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Simulate Native Crash") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "simulate_crash",
                                screen: "SettingsView"
                            )
                            SentrySDK.addBreadcrumb(Breadcrumb(
                                level: .fatal,
                                category: "sentry.demo"
                            ))
                            showingCrashAlert = true
                            span?.finish()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .alert(isPresented: $showingCrashAlert) {
                            Alert(
                                title: Text("Simulate Crash"),
                                message: Text("This will cause the app to crash immediately. The crash report will be sent to Sentry on next launch."),
                                primaryButton: .destructive(Text("Confirm Crash")) {
                                    SentrySDK.crash()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button("Advanced Sentry Demo") {
                            showingSentryDemo = true
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .sheet(isPresented: $showingSentryDemo) {
                            SentryDemoSheet(audioPlayer: audioPlayer, bluetoothService: bluetoothService)
                        }
                        
                        Toggle("Verbose Logging", isOn: $isLoggingVerbose)
                            .onChange(of: isLoggingVerbose) { enabled in
                                let span = SessionManager.shared.createUserInteractionSpan(
                                    action: "toggle_logging",
                                    screen: "SettingsView"
                                )
                                SentrySDK.addBreadcrumb(Breadcrumb(
                                    level: .info,
                                    category: "sentry.settings"
                                ))
                                span?.setTag(value: "\(enabled)", key: "verbose_enabled")
                                span?.finish()
                            }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // App Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("App Information")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                        }
                        
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("1")
                        }
                        
                        HStack {
                            Text("Sentry SDK Version")
                            Spacer()
                            Text("8.53.2")
                        }
                        
                        HStack {
                            Text("Target Device")
                            Spacer()
                            Text("iOS 14+")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .onAppear {
                // Create screen load span as part of the active session
                let screenLoadSpan = SessionManager.shared.createScreenLoadSpan(screenName: "SettingsView")
                
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .info,
                    category: "ui.navigation"
                ))
                
                // Finish screen load span after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    screenLoadSpan?.setTag(value: "loaded", key: "load_status")
                    screenLoadSpan?.finish()
                }
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Demo Error Triggered"),
                message: Text("A demonstration error has been sent to Sentry. Check your Sentry dashboard to see how error monitoring works."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Advanced Sentry Demo Sheet

struct SentryDemoSheet: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @ObservedObject var bluetoothService: BluetoothService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var customTag = ""
    @State private var customMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Performance Monitoring
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Monitoring")
                            .font(.headline)
                        
                        Button("Generate Random Breadcrumbs") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "generate_breadcrumbs",
                                screen: "SettingsView"
                            )
                            
                            for _ in 0..<3 {
                                SentrySDK.addBreadcrumb(Breadcrumb(
                                    level: .info,
                                    category: "user.action"
                                ))
                            }
                            
                            span?.setData(value: 3, key: "breadcrumbs_generated")
                            span?.finish()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                                            Button("Start Performance Transaction") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "start_performance_test",
                                screen: "SettingsView"
                            )
                            // Simulate some async work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                span?.setTag(value: "completed", key: "operation_status")
                                span?.finish()
                            }
                        }
                    }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Error Monitoring
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Error Monitoring")
                            .font(.headline)
                        
                        TextField("Custom Error Message", text: $customMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Send Custom Error") {
                            guard !customMessage.isEmpty else { return }
                            
                            let error = NSError(domain: "CustomDemo", code: 200, userInfo: [
                                NSLocalizedDescriptionKey: customMessage
                            ])
                            
                            SentrySDK.capture(error: error) { scope in
                                scope.setTag(value: "user_generated", key: "error_type")
                                scope.setContext(value: [
                                    "connected_device": bluetoothService.connectedDevice?.name ?? "None",
                                    "current_track": audioPlayer.currentTrack?.title ?? "None",
                                    "playback_state": audioPlayer.playbackState.rawValue,
                                    "volume": audioPlayer.audioSettings.volume
                                ], key: "app_state")
                            }
                            
                            customMessage = ""
                        }
                        .disabled(customMessage.isEmpty)
                        .padding()
                        .background(customMessage.isEmpty ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Sentry Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
    }
}

// MARK: - Sentry Data Simulator

@MainActor
class SentryDataSimulator: ObservableObject {
    @Published var isSimulating = false
    @Published var simulationProgress = 0
    @Published var totalSessions = 0
    
    private let bluetoothService: BluetoothService
    private let audioPlayer: AudioPlayerService
    
    init(bluetoothService: BluetoothService, audioPlayer: AudioPlayerService) {
        self.bluetoothService = bluetoothService
        self.audioPlayer = audioPlayer
    }
    
    func runSimulation(sessionCount: Int = 150) async {
        await MainActor.run {
            isSimulating = true
            simulationProgress = 0
            totalSessions = sessionCount
        }
        
        print("🎬 Starting simulation: \(sessionCount) user sessions")
        print("📊 Generating dashboard data for span operations:")
        print("   • bt.scan (Device Scan Performance)")
        print("   • bt.write.command (Command Latency)")
        print("   • device.response (ACK Response Times)")
        print("   • bt.connection (Connection Success Rates)")
        print("   • ui.action.user (UI Responsiveness & Controls)")
        print("   • ui.screen.load (Screen Load Performance)")
        print("")
        
        for sessionNum in 1...sessionCount {
            await simulateUserSession(sessionId: sessionNum)
            
            await MainActor.run {
                simulationProgress = sessionNum
            }
            
            // Small delay to spread events over time  
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 50...200) * 1_000_000))
        }
        
        await MainActor.run {
            isSimulating = false
        }
        
        print("\n🎉 Simulation Complete!")
        print("📈 Check Sentry for generated metrics in:")
        print("   • Performance > Transactions")
        print("   • Discover > Spans")
        print("   • Your custom dashboards")
    }
    
    private func simulateUserSession(sessionId: Int) async {
        let personas = ["happy_user", "impatient_user", "power_user", "casual_user", "troubled_user"]
        let scenarios = ["optimal", "weak_signal", "interference", "low_battery", "firmware_lag"]
        let devices = BluetoothDevice.generateSampleDevices()
        
        let persona = personas.randomElement()!
        let scenario = scenarios.randomElement()!
        let device = devices.randomElement()!
        
        let sessionTransaction = SentrySDK.startTransaction(
            name: "User Session - \(persona)",
            operation: "app.session"
        )
        
        sessionTransaction.setTag(value: persona, key: "user_persona")
        sessionTransaction.setTag(value: scenario, key: "device_scenario")
        sessionTransaction.setTag(value: "simulation", key: "data_source")
        sessionTransaction.setTag(value: device.name, key: "target_device")
        
        SentrySDK.setUser(User(userId: "\(persona)-\(String(format: "%03d", sessionId))"))
        
        let actionCount = Int.random(in: 5...15)
        let errorRate = persona == "troubled_user" ? 0.2 : 0.05
        
        print("👤 Session \(sessionId): \(persona) → \(device.name) (\(scenario))")
        
        // 1. Screen Load Simulation
        await simulateScreenLoad("ContentView", scenario: scenario, transaction: sessionTransaction)
        
        // 2. Device Scan Simulation (to populate scan_status, devices_found)
        await simulateDeviceScan(scenario: scenario, transaction: sessionTransaction)
        
        // 3. Device Connection Simulation
        await simulateDeviceConnection(device, scenario: scenario, transaction: sessionTransaction)
        
        // 4. One-time track selection user action (user_action: track_select)
        await simulateTrackSelection(transaction: sessionTransaction)
        
        // 5. Multiple Audio Commands + UI control interactions
        for _ in 1...actionCount {
            await simulateAudioCommand(
                device: device,
                scenario: scenario,
                transaction: sessionTransaction,
                shouldFail: Double.random(in: 0...1) < errorRate
            )
            // Emit a UI control span (control_type + connected_device). Sometimes volume to include volume_level.
            await simulateUIControlInteraction(device: device, transaction: sessionTransaction)
            
            // User delay between actions
            let delay = Double.random(in: 0.3...2.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        sessionTransaction.finish()
    }
    
    // Simulate a Bluetooth scan to generate bt.scan spans with scan_status and devices_found
    private func simulateDeviceScan(scenario: String, transaction: Span) async {
        let scanSpan = transaction.startChild(
            operation: "bt.scan",
            description: "Bluetooth Device Scan"
        )
        // Randomized scan outcome similar to real app
        let scanDelay = Double.random(in: 1500...4000)
        let outcomeRoll = Double.random(in: 0...1)
        try? await Task.sleep(nanoseconds: UInt64(scanDelay * 1_000_000))
        var devicesFound = 0
        if outcomeRoll > 0.5 {
            // success
            devicesFound = Int.random(in: 3...5)
            scanSpan.setTag(value: "completed", key: "scan_status")
            scanSpan.setTag(value: "success", key: "scan_result")
        } else {
            // failure variants
            let failureRoll = Double.random(in: 0...1)
            if failureRoll < 0.3 {
                devicesFound = 0
                scanSpan.setTag(value: "failure", key: "scan_status")
                scanSpan.setTag(value: "no_devices", key: "failure_reason")
                scanSpan.setTag(value: "bluetooth_timeout", key: "scan_result")
            } else if failureRoll < 0.6 {
                devicesFound = Int.random(in: 1...2)
                scanSpan.setTag(value: "partial", key: "scan_status")
                scanSpan.setTag(value: "incomplete_discovery", key: "failure_reason")
                scanSpan.setTag(value: "degraded_signal", key: "scan_result")
            } else {
                devicesFound = Int.random(in: 2...3)
                scanSpan.setTag(value: "timeout", key: "scan_status")
                scanSpan.setTag(value: "scan_timeout", key: "failure_reason")
                scanSpan.setTag(value: "stale_cache", key: "scan_result")
                scanSpan.setTag(value: "true", key: "using_cached_results")
            }
        }
        scanSpan.setData(value: devicesFound, key: "devices_found")
        scanSpan.setData(value: Int(scanDelay), key: "scan_duration_ms")
        scanSpan.finish()
    }
    
    // Simulate a user track selection to populate user_action: track_select and related fields
    private func simulateTrackSelection(transaction: Span) async {
        let span = transaction.startChild(
            operation: "ui.action.user",
            description: "User track selection"
        )
        span.setTag(value: "track_select", key: "user_action")
        span.setTag(value: "PlaylistView", key: "screen_name")
        // Example metadata that matches PlaylistView behavior
        span.setTag(value: "false", key: "was_playing")
        span.setTag(value: String(Int.random(in: 0...9)), key: "track_index")
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 40...120) * 1_000_000))
        span.finish()
    }
    
    // Simulate user control interactions to create ui.action.user spans with control_type and volume_level
    private func simulateUIControlInteraction(device: BluetoothDevice, transaction: Span) async {
        enum Control: CaseIterable { case playPause, skipNext, skipPrev, volume }
        let control = Control.allCases.randomElement()!
        let span = transaction.startChild(
            operation: "ui.action.user",
            description: "Simulated UI Control"
        )
        span.setTag(value: "NowPlayingView", key: "screen_name")
        span.setTag(value: device.name, key: "connected_device")
        span.setTag(value: "true", key: "is_user_action")
        switch control {
        case .playPause:
            span.setTag(value: "audio.control.playpause", key: "control_type")
            span.setTag(value: Bool.random() ? "play" : "pause", key: "action")
        case .skipNext:
            span.setTag(value: "audio.control.next", key: "control_type")
        case .skipPrev:
            span.setTag(value: "audio.control.previous", key: "control_type")
        case .volume:
            span.setTag(value: "audio.volume.adjust", key: "control_type")
            let level = Double.random(in: 0...1)
            span.setData(value: level, key: "volume_level")
        }
        // Basic duration to make the span visible in charts
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 20...120) * 1_000_000))
        span.finish()
    }

    private func simulateScreenLoad(_ screenName: String, scenario: String, transaction: Span) async {
        let loadSpan = transaction.startChild(
            operation: "ui.screen.load",
            description: "Load \(screenName)"
        )
        
        loadSpan.setTag(value: screenName, key: "screen_name")
        loadSpan.setTag(value: "swiftui", key: "ui_framework")
        loadSpan.setTag(value: scenario, key: "device_scenario")
        
        let baseLoadTime = Double.random(in: 80...180)
        let scenarioMultiplier = scenario == "optimal" ? 1.0 : Double.random(in: 1.5...2.5)
        let loadTime = baseLoadTime * scenarioMultiplier
        
        try? await Task.sleep(nanoseconds: UInt64(loadTime * 1_000_000))
        
        loadSpan.setData(value: loadTime, key: "load_time_ms")
        loadSpan.setTag(value: loadTime > 400 ? "slow" : "normal", key: "load_performance")
        loadSpan.finish()
    }
    
    private func simulateDeviceConnection(_ device: BluetoothDevice, scenario: String, transaction: Span) async {
        let connectionSpan = transaction.startChild(
            operation: "bt.connection",
            description: "Connect to \(device.name)"
        )
        
        connectionSpan.setTag(value: device.name, key: "device_name")
        connectionSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        connectionSpan.setTag(value: scenario, key: "device_scenario")
        connectionSpan.setData(value: device.signalStrength, key: "signal_strength")
        
        if let battery = device.batteryLevel {
            connectionSpan.setData(value: battery, key: "battery_level")
        }
        
        let baseConnectionTime = Double.random(in: 800...2500)
        let scenarioImpact = scenario == "optimal" ? 1.0 : Double.random(in: 1.5...3.0)
        let connectionTime = baseConnectionTime * scenarioImpact
        
        try? await Task.sleep(nanoseconds: UInt64(connectionTime * 1_000_000))
        
        let successRate = scenario == "optimal" ? 0.98 : 0.85
        let willSucceed = Double.random(in: 0...1) < successRate
        
        if willSucceed {
            connectionSpan.setTag(value: "success", key: "connection_result")
            connectionSpan.setData(value: connectionTime, key: "connection_time_ms")
            print("  ✅ Connected in \(Int(connectionTime))ms")
        } else {
            connectionSpan.setTag(value: "failed", key: "connection_result")
            connectionSpan.setTag(value: "timeout", key: "failure_reason")
            
            let error = NSError(
                domain: "BluetoothConnectionError",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to connect to \(device.name)",
                    "device_scenario": scenario,
                    "signal_strength": device.signalStrength
                ]
            )
            SentrySDK.capture(error: error)
            print("  ❌ Connection failed")
        }
        
        connectionSpan.finish()
    }
    
    private func simulateAudioCommand(device: BluetoothDevice, scenario: String, transaction: Span, shouldFail: Bool = false) async {
        let commands = ["PLAY", "PAUSE", "VOLUME_UP", "VOLUME_DOWN", "NEXT_TRACK", "PREV_TRACK", "SHUFFLE"]
        let command = commands.randomElement()!
        
        let commandSpan = transaction.startChild(
            operation: "bt.write.command",
            description: "BLE Command: \(command)"
        )
        
        // Tag with dashboard-relevant attributes
        commandSpan.setTag(value: command, key: "command_type")
        commandSpan.setTag(value: device.name, key: "device_name")
        commandSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        commandSpan.setTag(value: scenario, key: "device_scenario")
        commandSpan.setTag(value: "true", key: "is_user_action")
        commandSpan.setTag(value: "bluetooth", key: "network_type")
        commandSpan.setData(value: device.signalStrength, key: "signal_strength")
        
        let baseWriteLatency = Double.random(in: 15...80)
        let baseAckLatency = Double.random(in: 20...120)
        let scenarioMultiplier = scenario == "optimal" ? 1.0 : Double.random(in: 1.5...3.0)
        
        let writeLatency = baseWriteLatency * scenarioMultiplier
        let ackLatency = baseAckLatency * scenarioMultiplier
        
        // Simulate write phase
        try? await Task.sleep(nanoseconds: UInt64(writeLatency * 1_000_000))
        
        if shouldFail {
            commandSpan.setTag(value: "failed", key: "command_status")
            commandSpan.setTag(value: "timeout", key: "failure_reason")
            commandSpan.setData(value: writeLatency, key: "write_latency_ms")
            
            let error = NSError(
                domain: "BluetoothCommandError",
                code: 2001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Command \(command) failed",
                    "command_type": command,
                    "device_name": device.name,
                    "device_scenario": scenario
                ]
            )
            SentrySDK.capture(error: error)
            
            commandSpan.finish()
            print("    ❌ \(command) failed")
            return
        }
        
        // Simulate ACK response
        let responseSpan = commandSpan.startChild(
            operation: "device.response",
            description: "Device ACK: \(command)"
        )
        
        responseSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        responseSpan.setTag(value: "bluetooth_ack", key: "response_type")
        responseSpan.setTag(value: scenario, key: "device_scenario")
        
        try? await Task.sleep(nanoseconds: UInt64(ackLatency * 1_000_000))
        
        let totalLatency = writeLatency + ackLatency
        
        // Tag with metrics for dashboard queries
        commandSpan.setTag(value: "success", key: "command_status")
        commandSpan.setData(value: writeLatency, key: "write_latency_ms")
        commandSpan.setData(value: totalLatency, key: "total_latency_ms")
        
        responseSpan.setData(value: ackLatency, key: "ack_latency_ms")
        responseSpan.setTag(value: "received", key: "ack_status")
        responseSpan.setData(value: 200, key: "status_code")
        
        // Simulate UI state update
        let renderSpan = commandSpan.startChild(
            operation: "ui.state.render",
            description: "Update UI after \(command)"
        )
        
        renderSpan.setTag(value: command.lowercased(), key: "state_change")
        renderSpan.setTag(value: "true", key: "is_mobile_vital")
        
        let renderTime = min(totalLatency * 0.15, 80.0)
        try? await Task.sleep(nanoseconds: UInt64(renderTime * 1_000_000))
        
        renderSpan.setData(value: renderTime, key: "render_time_ms")
        renderSpan.finish()
        
        responseSpan.finish()
        commandSpan.finish()
        
        print("    ✅ \(command): \(Int(totalLatency))ms total (\(Int(writeLatency))ms write + \(Int(ackLatency))ms ack)")
    }
}

struct SentryDataSimulatorView: View {
    @StateObject private var simulator: SentryDataSimulator
    @State private var sessionCount = 150
    
    init(bluetoothService: BluetoothService, audioPlayer: AudioPlayerService) {
        self._simulator = StateObject(wrappedValue: SentryDataSimulator(
            bluetoothService: bluetoothService,
            audioPlayer: audioPlayer
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sentry Dashboard Data Simulator")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Generate test data for performance dashboards")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Sessions:")
                Stepper("\(sessionCount)", value: $sessionCount, in: 50...500, step: 25)
                    .disabled(simulator.isSimulating)
            }
            
            if simulator.isSimulating {
                VStack {
                    ProgressView(value: Double(simulator.simulationProgress), total: Double(simulator.totalSessions))
                    Text("\(simulator.simulationProgress) of \(simulator.totalSessions) sessions")
                        .font(.caption)
                }
            }
            
            Button(action: {
                Task {
                    await simulator.runSimulation(sessionCount: sessionCount)
                }
            }) {
                HStack {
                    Image(systemName: simulator.isSimulating ? "stop.circle" : "play.circle")
                    Text(simulator.isSimulating ? "Running..." : "Start Simulation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(simulator.isSimulating ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(simulator.isSimulating)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Generated Span Operations:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Group {
                    Text("• bt.write.command (Command Latency)")
                    Text("• device.response (ACK Response)")
                    Text("• bt.connection (Connection Success)")
                    Text("• ui.action.user (UI Performance)")
                    Text("• ui.screen.load (Screen Load Times)")
                    Text("• Error patterns for alerts")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let bluetoothService = BluetoothService()
        let audioPlayer = AudioPlayerService(bluetoothService: bluetoothService)
        
        return SettingsView(audioPlayer: audioPlayer)
            .environmentObject(bluetoothService)
    }
} 