#!/usr/bin/env swift

import Foundation
import UIKit
import Sentry

/**
 * Bluetooth Remote App - User Interaction Simulator
 * 
 * This script simulates realistic user interactions to generate test data
 * for Sentry dashboards and alerts. It creates both good and bad user 
 * experiences to demonstrate critical monitoring scenarios.
 *
 * Based on the span operations found in BluetoothService and AudioPlayerService:
 * - bt.write.command (BLE command latency)
 * - device.response (ACK latency) 
 * - ui.action.user (UI interactions)
 * - ui.screen.load (screen loads)
 * - bt.connection (device connections)
 * - ui.state.render (state updates)
 */

class SentrySimulator {
    
    // User personas with different behavior patterns
    enum UserPersona: String, CaseIterable {
        case happyUser = "happy_user"
        case impatientUser = "impatient_user"  
        case powerUser = "power_user"
        case casualUser = "casual_user"
        case troubledUser = "troubled_user"
        
        var characteristics: (actionDelay: ClosedRange<Double>, errorProne: Bool, retryCount: Int) {
            switch self {
            case .happyUser: 
                return (2.0...5.0, false, 1)
            case .impatientUser: 
                return (0.5...1.5, true, 3)
            case .powerUser: 
                return (0.1...0.8, false, 2) 
            case .casualUser: 
                return (3.0...8.0, false, 1)
            case .troubledUser: 
                return (1.0...3.0, true, 5)
            }
        }
    }
    
    // Device types that affect performance differently
    enum SimulatedDevice: String, CaseIterable {
        case arcSoundbar = "Living Room Arc"
        case kitchenOne = "Kitchen One" 
        case bedroomMove = "Bedroom Move"
        case officeEra = "Office Era 100"
        case basementSub = "Basement Sub"
        
        var performanceProfile: (baseLatency: ClosedRange<Double>, reliabilityScore: Double, batteryLevel: Int?) {
            switch self {
            case .arcSoundbar: 
                return (15...40, 0.98, nil)
            case .kitchenOne: 
                return (20...50, 0.95, nil)
            case .bedroomMove: 
                return (25...80, 0.85, 65) // Battery powered, more variable
            case .officeEra: 
                return (18...45, 0.96, nil)
            case .basementSub: 
                return (30...120, 0.80, nil) // Weak signal in basement
            }
        }
    }
    
    // Commands that users typically perform  
    enum AudioCommand: String, CaseIterable {
        case play = "PLAY"
        case pause = "PAUSE" 
        case stop = "STOP"
        case volumeUp = "VOLUME_UP"
        case volumeDown = "VOLUME_DOWN"
        case nextTrack = "NEXT_TRACK"
        case prevTrack = "PREV_TRACK"
        case shuffle = "SHUFFLE"
        case repeat = "REPEAT"
        
        var expectedLatency: ClosedRange<Double> {
            switch self {
            case .play, .pause, .stop: 
                return 20...60
            case .volumeUp, .volumeDown: 
                return 15...40  
            case .nextTrack, .prevTrack: 
                return 40...100
            case .shuffle, .repeat: 
                return 25...70
            }
        }
    }
    
    // Initialize Sentry with demo configuration
    static func initializeSentry() {
        SentrySDK.start { options in
            options.dsn = "https://2cd5f78faaf215a707d856b152feace9@o4504052292517888.ingest.us.sentry.io/4509725305929728"
            options.environment = "simulation"
            options.releaseName = "bluetooth-remote@simulation-1.0.0"
            
            // Enable all performance features for comprehensive data
            options.tracesSampleRate = 1.0
            options.enableAutoPerformanceTracing = true
            options.enableTimeToFullDisplayTracing = true
            options.enablePerformanceV2 = true
            
            // Session tracking
            options.enableAutoSessionTracking = true
            options.enableAppHangTracking = true
            
            // Mobile Replay for demonstration
            options.sessionReplay.sessionSampleRate = 1.0
            options.sessionReplay.onErrorSampleRate = 1.0
            
            // Profiling for detailed analysis
            options.configureProfiling = { profilingOptions in
                profilingOptions.sessionSampleRate = 1.0
            }
        }
        
        print("✅ Sentry initialized for simulation")
    }
    
    // Start a user session with transaction
    func startUserSession(userId: String, persona: UserPersona) -> Span? {
        let sessionTransaction = SentrySDK.startTransaction(
            name: "User Session - \(persona.rawValue)",
            operation: "app.session"
        )
        
        // Set user context
        SentrySDK.setUser(User(
            userId: "\(persona.rawValue)-\(userId)",
            username: "\(persona.rawValue.capitalized) User",
            segment: persona.rawValue
        ))
        
        // Tag transaction with user characteristics
        sessionTransaction.setTag(value: persona.rawValue, key: "user_persona")
        sessionTransaction.setTag(value: "ios_simulator", key: "platform")
        sessionTransaction.setTag(value: "simulation", key: "data_source")
        
        return sessionTransaction
    }
    
    // Simulate device connection with realistic patterns
    func simulateDeviceConnection(device: SimulatedDevice, persona: UserPersona, sessionTransaction: Span?) {
        let connectionSpan = sessionTransaction?.startChild(
            operation: "bt.connection",
            description: "Connect to \(device.rawValue)"
        )
        
        let profile = device.performanceProfile
        let characteristics = persona.characteristics
        
        // Add connection context
        connectionSpan?.setTag(value: device.rawValue, key: "device_name")
        connectionSpan?.setTag(value: "soundbar", key: "device_type")
        connectionSpan?.setData(value: Int.random(in: 70...95), key: "signal_strength")
        
        if let battery = profile.batteryLevel {
            connectionSpan?.setData(value: battery, key: "battery_level")
        }
        
        // Simulate connection attempt based on device reliability
        let willSucceed = Double.random(in: 0...1) < profile.reliabilityScore
        let connectionTime = Double.random(in: 1.0...5.0)
        
        Thread.sleep(forTimeInterval: connectionTime)
        
        if willSucceed {
            connectionSpan?.setTag(value: "success", key: "connection_result")
            connectionSpan?.setData(value: connectionTime * 1000, key: "connection_time_ms")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "bluetooth.connection"
            ))
            
            print("📱 \(persona.rawValue) connected to \(device.rawValue) in \(Int(connectionTime * 1000))ms")
        } else {
            connectionSpan?.setTag(value: "failed", key: "connection_result")
            connectionSpan?.setTag(value: "timeout", key: "failure_reason")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .error,
                category: "bluetooth.connection.error"
            ))
            
            // Capture connection error
            let error = NSError(
                domain: "BluetoothError", 
                code: 1001, 
                userInfo: [NSLocalizedDescriptionKey: "Failed to connect to \(device.rawValue)"]
            )
            SentrySDK.capture(error: error)
            
            print("❌ \(persona.rawValue) failed to connect to \(device.rawValue)")
        }
        
        connectionSpan?.finish()
    }
    
    // Simulate BLE command with realistic latency patterns
    func simulateBLECommand(command: AudioCommand, device: SimulatedDevice, persona: UserPersona, sessionTransaction: Span?) {
        let commandSpan = sessionTransaction?.startChild(
            operation: "bt.write.command",
            description: "BLE Command: \(command.rawValue)"
        )
        
        let deviceProfile = device.performanceProfile
        let userCharacteristics = persona.characteristics
        
        // Tag command with context
        commandSpan?.setTag(value: command.rawValue, key: "command_type")
        commandSpan?.setTag(value: device.rawValue, key: "device_name")
        commandSpan?.setTag(value: "soundbar", key: "device_type")
        commandSpan?.setTag(value: "true", key: "is_user_action")
        commandSpan?.setTag(value: "bluetooth", key: "network_type")
        
        // Generate realistic latencies based on device and command type
        let baseLatency = command.expectedLatency
        let deviceLatencyMultiplier = deviceProfile.baseLatency.upperBound / 50.0
        
        let writeLatency = Double.random(in: baseLatency) * deviceLatencyMultiplier
        let ackLatency = Double.random(in: 20...120) * deviceLatencyMultiplier
        
        // Simulate failure scenarios for demonstration
        let shouldFail = userCharacteristics.errorProne && Double.random(in: 0...1) < 0.15
        
        // Phase 1: BLE Write
        Thread.sleep(forTimeInterval: writeLatency / 1000.0)
        
        if shouldFail {
            commandSpan?.setTag(value: "failed", key: "command_status")
            commandSpan?.setTag(value: "timeout", key: "failure_reason")
            commandSpan?.setData(value: writeLatency, key: "write_latency_ms")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .error,
                category: "mobile.network.error"
            ))
            
            // Capture command failure
            let error = NSError(
                domain: "BluetoothCommandError",
                code: 2001,
                userInfo: [NSLocalizedDescriptionKey: "Command \(command.rawValue) failed on \(device.rawValue)"]
            )
            SentrySDK.capture(error: error)
            
            commandSpan?.finish()
            print("❌ \(command.rawValue) command failed for \(persona.rawValue)")
            return
        }
        
        // Phase 2: Device Response (ACK)
        let responseSpan = commandSpan?.startChild(
            operation: "device.response",
            description: "Device ACK: \(command.rawValue)"
        )
        
        responseSpan?.setTag(value: "soundbar", key: "device_type")
        responseSpan?.setTag(value: "bluetooth_ack", key: "response_type")
        
        Thread.sleep(forTimeInterval: ackLatency / 1000.0)
        
        let totalLatency = writeLatency + ackLatency
        
        // Tag with performance metrics for dashboard queries
        commandSpan?.setTag(value: "success", key: "command_status")
        commandSpan?.setData(value: writeLatency, key: "write_latency_ms")
        commandSpan?.setData(value: totalLatency, key: "total_latency_ms")
        
        responseSpan?.setData(value: ackLatency, key: "ack_latency_ms")
        responseSpan?.setTag(value: "received", key: "ack_status")
        responseSpan?.setData(value: 200, key: "status_code")
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "mobile.network"
        ))
        
        print("✅ \(command.rawValue) completed for \(persona.rawValue): \(Int(totalLatency))ms total")
        
        responseSpan?.finish()
        commandSpan?.finish()
        
        // Simulate UI state render after successful command
        simulateUIStateRender(command: command, latency: totalLatency, sessionTransaction: sessionTransaction)
    }
    
    // Simulate UI state rendering after BLE operations
    func simulateUIStateRender(command: AudioCommand, latency: Double, sessionTransaction: Span?) {
        let renderSpan = sessionTransaction?.startChild(
            operation: "ui.state.render",
            description: "Update UI after \(command.rawValue)"
        )
        
        renderSpan?.setTag(value: command.rawValue.lowercased(), key: "state_change")
        renderSpan?.setTag(value: "true", key: "is_mobile_vital")
        renderSpan?.setTag(value: "swiftui", key: "ui_framework")
        
        // UI rendering time correlates with command latency
        let renderTime = min(latency * 0.1, 50.0) // Cap at 50ms
        Thread.sleep(forTimeInterval: renderTime / 1000.0)
        
        renderSpan?.setData(value: renderTime, key: "render_time_ms")
        renderSpan?.finish()
    }
    
    // Simulate user interaction patterns  
    func simulateUserInteraction(action: String, screen: String, persona: UserPersona, sessionTransaction: Span?) {
        let interactionSpan = sessionTransaction?.startChild(
            operation: "ui.action.user",
            description: "User \(action) on \(screen)"
        )
        
        interactionSpan?.setTag(value: action, key: "user_action")
        interactionSpan?.setTag(value: screen, key: "screen_name")
        interactionSpan?.setTag(value: "true", key: "is_user_action")
        interactionSpan?.setTag(value: persona.rawValue, key: "user_persona")
        
        let interactionTime = Double.random(in: 10...50)
        Thread.sleep(forTimeInterval: interactionTime / 1000.0)
        
        interactionSpan?.setData(value: interactionTime, key: "interaction_time_ms")
        interactionSpan?.finish()
        
        print("👆 \(persona.rawValue) performed \(action) on \(screen)")
    }
    
    // Simulate screen load performance
    func simulateScreenLoad(screenName: String, persona: UserPersona, sessionTransaction: Span?) {
        let screenSpan = sessionTransaction?.startChild(
            operation: "ui.screen.load",
            description: "Load \(screenName) Screen"
        )
        
        screenSpan?.setTag(value: screenName, key: "screen_name")
        screenSpan?.setTag(value: "swiftui", key: "ui_framework")
        
        // Screen load time varies by user behavior
        let loadTime = persona == .impatientUser ? 
            Double.random(in: 200...800) :  // Slower devices/poor conditions
            Double.random(in: 50...200)     // Normal conditions
        
        Thread.sleep(forTimeInterval: loadTime / 1000.0)
        
        screenSpan?.setData(value: loadTime, key: "load_time_ms")
        screenSpan?.setTag(value: "loaded", key: "load_status")
        screenSpan?.finish()
        
        print("📱 \(screenName) loaded for \(persona.rawValue): \(Int(loadTime))ms")
    }
    
    // Run complete user simulation
    func runUserSimulation(sessions: Int = 50) {
        SentrySimulator.initializeSentry()
        
        print("🚀 Starting simulation of \(sessions) user sessions...")
        print("📊 Generating data for dashboard metrics:")
        print("   - Command Latency (bt.write.command)")
        print("   - ACK Latency (device.response)")
        print("   - Connection Success Rate (bt.connection)")
        print("   - UI Responsiveness (ui.action.user)")
        print("   - Screen Load Performance (ui.screen.load)")
        print("")
        
        for sessionNum in 1...sessions {
            let persona = UserPersona.allCases.randomElement()!
            let device = SimulatedDevice.allCases.randomElement()!
            let sessionId = String(format: "%03d", sessionNum)
            
            print("--- Session \(sessionId): \(persona.rawValue) with \(device.rawValue) ---")
            
            // Start user session
            let sessionTransaction = startUserSession(userId: sessionId, persona: persona)
            
            // Simulate app usage flow
            simulateScreenLoad(screenName: "ContentView", persona: persona, sessionTransaction: sessionTransaction)
            
            simulateUserInteraction(action: "tab_navigation", screen: "ContentView", persona: persona, sessionTransaction: sessionTransaction)
            
            simulateScreenLoad(screenName: "DevicesView", persona: persona, sessionTransaction: sessionTransaction)
            
            // Attempt device connection
            simulateDeviceConnection(device: device, persona: persona, sessionTransaction: sessionTransaction)
            
            // If connection successful, simulate audio commands
            let connectionSuccessful = Double.random(in: 0...1) < device.performanceProfile.reliabilityScore
            
            if connectionSuccessful {
                simulateUserInteraction(action: "device_connection", screen: "DevicesView", persona: persona, sessionTransaction: sessionTransaction)
                
                // Navigate to now playing
                simulateUserInteraction(action: "tab_navigation", screen: "ContentView", persona: persona, sessionTransaction: sessionTransaction)
                simulateScreenLoad(screenName: "NowPlayingView", persona: persona, sessionTransaction: sessionTransaction)
                
                // Simulate multiple audio commands per session
                let commandCount = Int.random(in: 3...8)
                for _ in 1...commandCount {
                    let command = AudioCommand.allCases.randomElement()!
                    simulateBLECommand(command: command, device: device, persona: persona, sessionTransaction: sessionTransaction)
                    
                    simulateUserInteraction(action: "audio_control", screen: "NowPlayingView", persona: persona, sessionTransaction: sessionTransaction)
                    
                    // Random delay between commands based on user behavior
                    let delay = Double.random(in: persona.characteristics.actionDelay)
                    Thread.sleep(forTimeInterval: delay)
                }
                
                // Sometimes visit playlist or settings
                if Double.random(in: 0...1) < 0.4 {
                    simulateUserInteraction(action: "tab_navigation", screen: "ContentView", persona: persona, sessionTransaction: sessionTransaction)
                    simulateScreenLoad(screenName: "PlaylistView", persona: persona, sessionTransaction: sessionTransaction)
                }
            }
            
            // End session
            sessionTransaction?.finish()
            print("✅ Session \(sessionId) completed")
            print("")
            
            // Short delay between sessions to spread data over time
            Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.5))
        }
        
        print("🎉 Simulation complete! Generated data for \(sessions) user sessions")
        print("📈 Check your Sentry dashboard for:")
        print("   - Performance > Transactions")
        print("   - Discover > Spans")
        print("   - Your custom dashboards")
    }
}

// Main execution
let simulator = SentrySimulator()
simulator.runUserSimulation(sessions: 100) // Generate 100 user sessions