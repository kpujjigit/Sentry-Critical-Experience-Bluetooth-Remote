#!/usr/bin/env swift

import Foundation
import Combine

/**
 * Bluetooth Remote - Sentry Data Generator
 * 
 * This script programmatically generates test data for Sentry dashboards
 * by simulating the exact span operations and metrics that the app creates.
 * 
 * It generates the following span operations for dashboard creation:
 * - bt.write.command (Command Latency metrics)
 * - device.response (ACK Response times) 
 * - bt.connection (Connection Success rates)
 * - ui.action.user (UI Responsiveness)
 * - ui.screen.load (Screen Load performance)
 * 
 * This ensures you have realistic data patterns for building alerts and dashboards.
 */

// Simulate sending data to Sentry endpoint
struct SentryEvent {
    let timestamp: Date
    let type: String
    let op: String
    let description: String
    let tags: [String: String]
    let data: [String: Any]
    let duration: Double
}

class SentryDataGenerator {
    private var events: [SentryEvent] = []
    
    // User behavior patterns for realistic data
    enum UserPersona: String, CaseIterable {
        case happyUser = "happy_user"
        case impatientUser = "impatient_user"
        case powerUser = "power_user"
        case casualUser = "casual_user"
        case troubledUser = "troubled_user"
        
        var profile: (actions: Int, errorRate: Double, avgDelay: Double) {
            switch self {
            case .happyUser: return (8, 0.02, 3.0)
            case .impatientUser: return (15, 0.12, 0.8)
            case .powerUser: return (25, 0.05, 0.3)
            case .casualUser: return (5, 0.03, 5.0)
            case .troubledUser: return (12, 0.25, 2.0)
            }
        }
    }
    
    // Device scenarios affecting performance
    enum DeviceScenario: String, CaseIterable {
        case optimal = "optimal"
        case weakSignal = "weak_signal"
        case interference = "interference"
        case lowBattery = "low_battery"
        case firmwareLag = "firmware_lag"
        
        var impact: (latencyMultiplier: Double, errorRate: Double) {
            switch self {
            case .optimal: return (1.0, 0.02)
            case .weakSignal: return (2.5, 0.15)
            case .interference: return (1.8, 0.08)
            case .lowBattery: return (1.3, 0.12)
            case .firmwareLag: return (3.2, 0.06)
            }
        }
    }
    
    func generateTestData(sessions: Int = 200) {
        print("🎬 Generating \(sessions) user sessions for Sentry dashboards...")
        print("📊 Creating span operations:")
        print("   • bt.write.command (Command Latency)")
        print("   • device.response (ACK Response Times)")
        print("   • bt.connection (Connection Success Rates)")
        print("   • ui.action.user (UI Responsiveness)")
        print("   • ui.screen.load (Screen Load Performance)")
        print("")
        
        let devices = ["Living Room Arc", "Kitchen One", "Bedroom Move", "Office Era 100", "Basement Sub"]
        let commands = ["PLAY", "PAUSE", "VOLUME_UP", "VOLUME_DOWN", "NEXT_TRACK", "PREV_TRACK", "SHUFFLE"]
        
        for sessionNum in 1...sessions {
            let persona = UserPersona.allCases.randomElement()!
            let scenario = DeviceScenario.allCases.randomElement()!
            let device = devices.randomElement()!
            let profile = persona.profile
            let impact = scenario.impact
            
            print("👤 Session \(sessionNum): \(persona.rawValue) → \(device) (\(scenario.rawValue))")
            
            // 1. Screen Load
            generateScreenLoadSpan(
                screenName: "ContentView",
                scenario: scenario,
                sessionId: sessionNum
            )
            
            // 2. Device Connection
            generateConnectionSpan(
                device: device,
                scenario: scenario,
                sessionId: sessionNum,
                persona: persona
            )
            
            // 3. Multiple Audio Commands
            for actionNum in 1...profile.actions {
                let command = commands.randomElement()!
                
                generateAudioCommandSpan(
                    command: command,
                    device: device,
                    scenario: scenario,
                    sessionId: sessionNum,
                    actionNum: actionNum,
                    shouldFail: Double.random(in: 0...1) < profile.errorRate
                )
                
                // Random delay between commands
                Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.2))
            }
            
            // 4. UI Navigation
            if Double.random(in: 0...1) < 0.4 {
                generateUIActionSpan(
                    action: "tab_navigation",
                    screen: "PlaylistView",
                    scenario: scenario,
                    sessionId: sessionNum
                )
            }
        }
        
        print("\n🎉 Generated \(events.count) spans across \(sessions) sessions!")
        print("📈 This data would populate:")
        print("   • Performance dashboards")
        print("   • Error tracking alerts")
        print("   • User experience metrics")
        print("   • Device reliability reports")
        
        // Display summary statistics
        displaySummaryStats()
    }
    
    private func generateScreenLoadSpan(screenName: String, scenario: DeviceScenario, sessionId: Int) {
        let baseLoadTime = Double.random(in: 80...180)
        let impact = scenario.impact
        let loadTime = baseLoadTime * impact.latencyMultiplier
        
        let event = SentryEvent(
            timestamp: Date(),
            type: "span",
            op: "ui.screen.load",
            description: "Load \(screenName)",
            tags: [
                "screen_name": screenName,
                "ui_framework": "swiftui",
                "device_scenario": scenario.rawValue,
                "session_id": String(sessionId),
                "load_performance": loadTime > 400 ? "slow" : "normal"
            ],
            data: [
                "load_time_ms": loadTime,
                "user_id": "session-\(sessionId)"
            ],
            duration: loadTime
        )
        
        events.append(event)
        print("  📱 \(screenName) loaded: \(Int(loadTime))ms")
    }
    
    private func generateConnectionSpan(device: String, scenario: DeviceScenario, sessionId: Int, persona: UserPersona) {
        let baseConnectionTime = Double.random(in: 800...2500)
        let impact = scenario.impact
        let connectionTime = baseConnectionTime * impact.latencyMultiplier
        
        let willSucceed = Double.random(in: 0...1) > impact.errorRate
        let result = willSucceed ? "success" : "failed"
        
        let event = SentryEvent(
            timestamp: Date(),
            type: "span",
            op: "bt.connection",
            description: "Connect to \(device)",
            tags: [
                "device_name": device,
                "device_type": "soundbar",
                "device_scenario": scenario.rawValue,
                "connection_result": result,
                "user_persona": persona.rawValue,
                "session_id": String(sessionId),
                "failure_reason": willSucceed ? "" : "timeout"
            ],
            data: [
                "connection_time_ms": connectionTime,
                "signal_strength": Int.random(in: 70...95),
                "user_id": "session-\(sessionId)"
            ],
            duration: connectionTime
        )
        
        events.append(event)
        print("  \(willSucceed ? "✅" : "❌") Connection: \(Int(connectionTime))ms")
    }
    
    private func generateAudioCommandSpan(command: String, device: String, scenario: DeviceScenario, sessionId: Int, actionNum: Int, shouldFail: Bool) {
        let impact = scenario.impact
        let baseWriteLatency = Double.random(in: 15...80)
        let baseAckLatency = Double.random(in: 20...120)
        
        let writeLatency = baseWriteLatency * impact.latencyMultiplier
        let ackLatency = baseAckLatency * impact.latencyMultiplier
        let totalLatency = writeLatency + ackLatency
        
        // Main command span
        let commandEvent = SentryEvent(
            timestamp: Date(),
            type: "span", 
            op: "bt.write.command",
            description: "BLE Command: \(command)",
            tags: [
                "command_type": command,
                "device_name": device,
                "device_type": "soundbar",
                "device_scenario": scenario.rawValue,
                "command_status": shouldFail ? "failed" : "success",
                "is_user_action": "true",
                "network_type": "bluetooth",
                "session_id": String(sessionId),
                "action_number": String(actionNum),
                "failure_reason": shouldFail ? "timeout" : ""
            ],
            data: [
                "write_latency_ms": writeLatency,
                "total_latency_ms": totalLatency,
                "signal_strength": Int.random(in: 70...95),
                "user_id": "session-\(sessionId)"
            ],
            duration: totalLatency
        )
        
        events.append(commandEvent)
        
        if !shouldFail {
            // Device response span (child of command)
            let responseEvent = SentryEvent(
                timestamp: Date(),
                type: "span",
                op: "device.response",
                description: "Device ACK: \(command)",
                tags: [
                    "device_type": "soundbar",
                    "response_type": "bluetooth_ack",
                    "device_scenario": scenario.rawValue,
                    "ack_status": "received",
                    "session_id": String(sessionId),
                    "parent_command": command
                ],
                data: [
                    "ack_latency_ms": ackLatency,
                    "status_code": 200,
                    "user_id": "session-\(sessionId)"
                ],
                duration: ackLatency
            )
            
            events.append(responseEvent)
            
            // UI state render span
            let renderTime = min(totalLatency * 0.15, 80.0)
            let renderEvent = SentryEvent(
                timestamp: Date(),
                type: "span",
                op: "ui.state.render",
                description: "Update UI after \(command)",
                tags: [
                    "state_change": command.lowercased(),
                    "is_mobile_vital": "true",
                    "ui_framework": "swiftui",
                    "session_id": String(sessionId)
                ],
                data: [
                    "render_time_ms": renderTime,
                    "user_id": "session-\(sessionId)"
                ],
                duration: renderTime
            )
            
            events.append(renderEvent)
            print("    ✅ \(command): \(Int(totalLatency))ms total (\(Int(writeLatency))ms write + \(Int(ackLatency))ms ack)")
        } else {
            print("    ❌ \(command) failed")
        }
    }
    
    private func generateUIActionSpan(action: String, screen: String, scenario: DeviceScenario, sessionId: Int) {
        let interactionTime = Double.random(in: 10...50)
        
        let event = SentryEvent(
            timestamp: Date(),
            type: "span",
            op: "ui.action.user",
            description: "User \(action) on \(screen)",
            tags: [
                "user_action": action,
                "screen_name": screen,
                "is_user_action": "true",
                "device_scenario": scenario.rawValue,
                "session_id": String(sessionId)
            ],
            data: [
                "interaction_time_ms": interactionTime,
                "user_id": "session-\(sessionId)"
            ],
            duration: interactionTime
        )
        
        events.append(event)
        print("  👆 \(action) on \(screen)")
    }
    
    private func displaySummaryStats() {
        let commandSpans = events.filter { $0.op == "bt.write.command" }
        let responseSpans = events.filter { $0.op == "device.response" }
        let connectionSpans = events.filter { $0.op == "bt.connection" }
        let uiSpans = events.filter { $0.op.hasPrefix("ui.") }
        
        let successfulCommands = commandSpans.filter { $0.tags["command_status"] == "success" }
        let failedCommands = commandSpans.filter { $0.tags["command_status"] == "failed" }
        let successfulConnections = connectionSpans.filter { $0.tags["connection_result"] == "success" }
        
        print("\n📊 **Data Summary for Dashboard Creation:**")
        print("   • Total Spans: \(events.count)")
        print("   • Command Spans: \(commandSpans.count) (\(successfulCommands.count) success, \(failedCommands.count) failed)")
        print("   • Response Spans: \(responseSpans.count)")
        print("   • Connection Spans: \(connectionSpans.count) (\(successfulConnections.count) success)")
        print("   • UI Spans: \(uiSpans.count)")
        
        if !commandSpans.isEmpty {
            let commandLatencies = commandSpans.compactMap { $0.data["total_latency_ms"] as? Double }
            let avgLatency = commandLatencies.reduce(0, +) / Double(commandLatencies.count)
            let p95Latency = commandLatencies.sorted()[Int(Double(commandLatencies.count) * 0.95)]
            
            print("   • Avg Command Latency: \(Int(avgLatency))ms")
            print("   • P95 Command Latency: \(Int(p95Latency))ms")
        }
        
        let connectionSuccessRate = Double(successfulConnections.count) / Double(connectionSpans.count) * 100
        print("   • Connection Success Rate: \(String(format: "%.1f", connectionSuccessRate))%")
        
        print("\n🎯 **Ready for Dashboard Creation!**")
        print("Now you can build dashboards using these span operations:")
        print("1. Command Latency: `span.op:bt.write.command` → `p95(span.duration)`")
        print("2. ACK Response: `span.op:device.response` → `p95(span.duration)`") 
        print("3. Connection Success: `span.op:bt.connection` → `count_if(connection_result:success)/count()`")
        print("4. UI Performance: `span.op:ui.action.user` → `max(span.duration)`")
        print("5. Error Rates: `span.op:bt.write.command` → `count_if(command_status:failed)/count()`")
    }
}

// Run the simulation
print("🚀 Starting Sentry Dashboard Data Simulation")
print(String(repeating: "=", count: 50))

let generator = SentryDataGenerator()
generator.generateTestData(sessions: 150)

print("\n✅ Simulation Complete!")
print("📈 This represents the exact data patterns your app would generate")
print("🎛️ Use the instructions provided to build your Sentry dashboards")