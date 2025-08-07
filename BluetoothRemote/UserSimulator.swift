import Foundation
import SwiftUI
import Sentry

/**
 * UserSimulator - Generates realistic test data for Sentry dashboards
 * 
 * Simulates hundreds of user interactions to populate dashboards with:
 * - Command latency metrics (good and bad patterns)
 * - Connection success/failure rates  
 * - UI responsiveness data
 * - Error scenarios for alerting
 */

@MainActor
class UserSimulator: ObservableObject {
    @Published var isSimulating = false
    @Published var simulationProgress = 0
    @Published var totalSessions = 0
    
    private let bluetoothService: BluetoothService
    private let audioPlayer: AudioPlayerService
    
    init(bluetoothService: BluetoothService, audioPlayer: AudioPlayerService) {
        self.bluetoothService = bluetoothService
        self.audioPlayer = audioPlayer
    }
    
    // User personas for different behavior patterns
    enum UserPersona: String, CaseIterable {
        case happyUser = "happy_user"
        case impatientUser = "impatient_user"
        case powerUser = "power_user" 
        case casualUser = "casual_user"
        case troubledUser = "troubled_user"
        
        var sessionProfile: (actions: Int, errorRate: Double, avgDelay: Double) {
            switch self {
            case .happyUser: return (8, 0.02, 3.0)
            case .impatientUser: return (15, 0.12, 0.8)
            case .powerUser: return (25, 0.05, 0.3)
            case .casualUser: return (5, 0.03, 5.0)
            case .troubledUser: return (12, 0.25, 2.0)
            }
        }
    }
    
    // Device scenarios that create different performance patterns
    enum DeviceScenario: String, CaseIterable {
        case optimal = "optimal"
        case weakSignal = "weak_signal"
        case interference = "interference"
        case lowBattery = "low_battery"
        case firmware_lag = "firmware_lag"
        
        var performanceImpact: (latencyMultiplier: Double, errorRate: Double) {
            switch self {
            case .optimal: return (1.0, 0.02)
            case .weakSignal: return (2.5, 0.15)
            case .interference: return (1.8, 0.08)
            case .lowBattery: return (1.3, 0.12)
            case .firmware_lag: return (3.2, 0.06)
            }
        }
    }
    
    // Run comprehensive user simulation
    func runSimulation(sessionCount: Int = 150) async {
        await MainActor.run {
            isSimulating = true
            simulationProgress = 0
            totalSessions = sessionCount
        }
        
        print("🎬 Starting simulation: \(sessionCount) user sessions")
        print("📊 Generating dashboard data for:")
        print("   • Command Latency (p95 metrics)")
        print("   • ACK Response Times")
        print("   • Connection Success Rates")
        print("   • UI Responsiveness")
        print("   • Error Patterns\n")
        
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
        print("📈 Check Sentry for:")
        print("   • Performance > Transactions")
        print("   • Discover > Spans") 
        print("   • Custom dashboards with generated metrics")
    }
    
    private func simulateUserSession(sessionId: Int) async {
        let persona = UserPersona.allCases.randomElement()!
        let deviceScenario = DeviceScenario.allCases.randomElement()!
        let device = BluetoothDevice.generateSampleDevices().randomElement()!
        
        // Start user session transaction
        let sessionTransaction = SentrySDK.startTransaction(
            name: "User Session - \(persona.rawValue)",
            operation: "app.session"
        )
        
        sessionTransaction.setTag(value: persona.rawValue, key: "user_persona")
        sessionTransaction.setTag(value: deviceScenario.rawValue, key: "device_scenario")
        sessionTransaction.setTag(value: "simulation", key: "data_source")
        sessionTransaction.setTag(value: device.name, key: "target_device")
        
        // Set user context
        SentrySDK.setUser(User(
            userId: "\(persona.rawValue)-\(String(format: "%03d", sessionId))",
            username: "\(persona.rawValue.capitalized) User",
            segment: persona.rawValue
        ))
        
        let profile = persona.sessionProfile
        
        print("👤 Session \(sessionId): \(persona.rawValue) → \(device.name) (\(deviceScenario.rawValue))")
        
        // 1. App Launch & Screen Load
        await simulateScreenLoad("ContentView", scenario: deviceScenario, transaction: sessionTransaction)
        
        // 2. Device Discovery & Connection
        await simulateDeviceConnection(device, scenario: deviceScenario, transaction: sessionTransaction)
        
        // 3. Navigation to Now Playing
        await simulateNavigation("NowPlayingView", scenario: deviceScenario, transaction: sessionTransaction)
        
        // 4. Multiple Audio Commands (core user actions)
        for actionNum in 1...profile.actions {
            await simulateAudioCommand(
                device: device,
                scenario: deviceScenario, 
                transaction: sessionTransaction,
                shouldFail: Double.random(in: 0...1) < profile.errorRate
            )
            
            // User thinking/reaction time
            let delay = Double.random(in: 0.5...(profile.avgDelay * 2.0))
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // 5. Sometimes explore other features
        if Double.random(in: 0...1) < 0.3 {
            await simulateNavigation("PlaylistView", scenario: deviceScenario, transaction: sessionTransaction)
        }
        
        if Double.random(in: 0...1) < 0.2 {
            await simulateNavigation("SettingsView", scenario: deviceScenario, transaction: sessionTransaction)
        }
        
        sessionTransaction.finish()
    }
    
    private func simulateScreenLoad(_ screenName: String, scenario: DeviceScenario, transaction: Span) async {
        let loadSpan = transaction.startChild(
            operation: "ui.screen.load",
            description: "Load \(screenName)"
        )
        
        loadSpan.setTag(value: screenName, key: "screen_name")
        loadSpan.setTag(value: "swiftui", key: "ui_framework")
        loadSpan.setTag(value: scenario.rawValue, key: "device_scenario")
        
        // Base load time + scenario impact
        let baseLoadTime = Double.random(in: 80...180)
        let impactedLoadTime = baseLoadTime * scenario.performanceImpact.latencyMultiplier
        
        try? await Task.sleep(nanoseconds: UInt64(impactedLoadTime * 1_000_000))
        
        loadSpan.setData(value: impactedLoadTime, key: "load_time_ms")
        loadSpan.setTag(value: impactedLoadTime > 400 ? "slow" : "normal", key: "load_performance")
        loadSpan.finish()
    }
    
    private func simulateDeviceConnection(_ device: BluetoothDevice, scenario: DeviceScenario, transaction: Span) async {
        let connectionSpan = transaction.startChild(
            operation: "bt.connection",
            description: "Connect to \(device.name)"
        )
        
        connectionSpan.setTag(value: device.name, key: "device_name")
        connectionSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        connectionSpan.setTag(value: scenario.rawValue, key: "device_scenario")
        connectionSpan.setData(value: device.signalStrength, key: "signal_strength")
        
        if let battery = device.batteryLevel {
            connectionSpan.setData(value: battery, key: "battery_level")
        }
        
        // Connection time varies by scenario
        let baseConnectionTime = Double.random(in: 800...2500)
        let connectionTime = baseConnectionTime * scenario.performanceImpact.latencyMultiplier
        
        try? await Task.sleep(nanoseconds: UInt64(connectionTime * 1_000_000))
        
        // Success/failure based on scenario
        let willSucceed = Double.random(in: 0...1) > scenario.performanceImpact.errorRate
        
        if willSucceed {
            connectionSpan.setTag(value: "success", key: "connection_result")
            connectionSpan.setData(value: connectionTime, key: "connection_time_ms")
            print("  ✅ Connected in \(Int(connectionTime))ms")
        } else {
            connectionSpan.setTag(value: "failed", key: "connection_result")
            connectionSpan.setTag(value: "timeout", key: "failure_reason")
            
            // Capture connection error for error tracking
            let error = NSError(
                domain: "BluetoothConnectionError",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to connect to \(device.name)",
                    "device_scenario": scenario.rawValue,
                    "signal_strength": device.signalStrength
                ]
            )
            SentrySDK.capture(error: error)
            print("  ❌ Connection failed")
        }
        
        connectionSpan.finish()
    }
    
    private func simulateNavigation(_ screenName: String, scenario: DeviceScenario, transaction: Span) async {
        let navSpan = transaction.startChild(
            operation: "ui.action.user",
            description: "Navigate to \(screenName)"
        )
        
        navSpan.setTag(value: "navigation", key: "user_action")
        navSpan.setTag(value: screenName, key: "screen_name")
        navSpan.setTag(value: scenario.rawValue, key: "device_scenario")
        
        let navTime = Double.random(in: 50...150)
        try? await Task.sleep(nanoseconds: UInt64(navTime * 1_000_000))
        
        navSpan.setData(value: navTime, key: "navigation_time_ms")
        navSpan.finish()
        
        // Also simulate the screen load
        await simulateScreenLoad(screenName, scenario: scenario, transaction: transaction)
    }
    
    private func simulateAudioCommand(device: BluetoothDevice, scenario: DeviceScenario, transaction: Span, shouldFail: Bool = false) async {
        let commands = ["PLAY", "PAUSE", "VOLUME_UP", "VOLUME_DOWN", "NEXT_TRACK", "PREV_TRACK", "SHUFFLE"]
        let command = commands.randomElement()!
        
        let commandSpan = transaction.startChild(
            operation: "bt.write.command",
            description: "BLE Command: \(command)"
        )
        
        // Tag with all dashboard-relevant attributes
        commandSpan.setTag(value: command, key: "command_type")
        commandSpan.setTag(value: device.name, key: "device_name")
        commandSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        commandSpan.setTag(value: scenario.rawValue, key: "device_scenario")
        commandSpan.setTag(value: "true", key: "is_user_action")
        commandSpan.setTag(value: "bluetooth", key: "network_type")
        commandSpan.setData(value: device.signalStrength, key: "signal_strength")
        
        // Realistic latency patterns
        let baseWriteLatency = Double.random(in: 15...80)
        let baseAckLatency = Double.random(in: 20...120)
        
        let impact = scenario.performanceImpact
        let writeLatency = baseWriteLatency * impact.latencyMultiplier
        let ackLatency = baseAckLatency * impact.latencyMultiplier
        
        // Simulate write phase
        try? await Task.sleep(nanoseconds: UInt64(writeLatency * 1_000_000))
        
        if shouldFail {
            commandSpan.setTag(value: "failed", key: "command_status")
            commandSpan.setTag(value: "timeout", key: "failure_reason")
            commandSpan.setData(value: writeLatency, key: "write_latency_ms")
            
            // Capture command error
            let error = NSError(
                domain: "BluetoothCommandError",
                code: 2001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Command \(command) failed",
                    "command_type": command,
                    "device_name": device.name,
                    "device_scenario": scenario.rawValue
                ]
            )
            SentrySDK.capture(error: error)
            
            commandSpan.finish()
            print("    ❌ \(command) failed")
            return
        }
        
        // Simulate ACK response as child span
        let responseSpan = commandSpan.startChild(
            operation: "device.response",
            description: "Device ACK: \(command)"
        )
        
        responseSpan.setTag(value: device.deviceType.rawValue, key: "device_type")
        responseSpan.setTag(value: "bluetooth_ack", key: "response_type")
        responseSpan.setTag(value: scenario.rawValue, key: "device_scenario")
        
        try? await Task.sleep(nanoseconds: UInt64(ackLatency * 1_000_000))
        
        let totalLatency = writeLatency + ackLatency
        
        // Tag with performance metrics for dashboard queries
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

// MARK: - Simulation UI Controls

struct SimulationControlView: View {
    @StateObject private var simulator: UserSimulator
    @State private var sessionCount = 150
    
    init(bluetoothService: BluetoothService, audioPlayer: AudioPlayerService) {
        self._simulator = StateObject(wrappedValue: UserSimulator(
            bluetoothService: bluetoothService,
            audioPlayer: audioPlayer
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sentry Data Simulator")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Generate test data for dashboard metrics")
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
                Text("Generated Metrics:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Group {
                    Text("• Command Latency (span.op:bt.write.command)")
                    Text("• ACK Response (span.op:device.response)")
                    Text("• Connection Success (span.op:bt.connection)")
                    Text("• UI Performance (span.op:ui.action.user)")
                    Text("• Error Patterns for alerts")
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