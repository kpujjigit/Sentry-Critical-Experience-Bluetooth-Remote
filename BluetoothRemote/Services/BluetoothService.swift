import Foundation
import Combine
import Sentry

@MainActor
class BluetoothService: ObservableObject {
    @Published var availableDevices: [BluetoothDevice] = []
    @Published var connectedDevice: BluetoothDevice?
    @Published var isScanning: Bool = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: BluetoothError?

    enum ConnectionState: String, CaseIterable {
        case disconnected = "Disconnected"
        case connecting = "Connecting..."
        case connected = "Connected"
        case failed = "Connection Failed"
        
        var displayText: String {
            switch self {
            case .disconnected: return "Not Connected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .failed: return "Connection Failed"
            }
        }
    }
    
    enum BluetoothError: Error, LocalizedError {
        case deviceNotFound
        case connectionTimeout
        case disconnectionFailed
        case scanningFailed
        case bluetoothUnavailable
        case commandFailed(String)
        case ackTimeout
        
        var errorDescription: String? {
            switch self {
            case .deviceNotFound: return "Device not found"
            case .connectionTimeout: return "Connection timed out"
            case .disconnectionFailed: return "Failed to disconnect"
            case .scanningFailed: return "Bluetooth scanning failed"
            case .bluetoothUnavailable: return "Bluetooth is not available"
            case .commandFailed(let command): return "Command '\(command)' failed"
            case .ackTimeout: return "Device acknowledgment timeout"
            }
        }
    }
    
    init() {
        setupInitialDevices()
    }
    
    func startScanning() {
        guard !isScanning else { return }
        
        isScanning = true
        
        // Create scan span as part of the active session
        let scanSpan = SessionManager.shared.createBluetoothSpan(
            operation: "scan",
            description: "Bluetooth Device Scan"
        )
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.scan"
        ))
        
        // 🎯 DEMO: Create artificial scan failure scenarios (50% chance to fail)
        let scanOutcome = Double.random(in: 0...1)
        let scanDelay = Double.random(in: 1.5...4.0) // Variable scan time
        
        // Simulate device discovery with potential failures
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDelay) {
            self.isScanning = false
            
            if scanOutcome > 0.5 {
                // 50% Success - Full device discovery
                self.availableDevices = BluetoothDevice.generateSampleDevices()
                scanSpan?.setData(value: self.availableDevices.count, key: "devices_found")
                scanSpan?.setTag(value: "completed", key: "scan_status")
                scanSpan?.setTag(value: "success", key: "scan_result")
                
                print("✅ Bluetooth scan completed successfully - found \(self.availableDevices.count) devices")
                
            } else {
                // 50% Failure scenarios with different outcomes
                let failureType = Double.random(in: 0...1)
                
                if failureType < 0.3 {
                    // 30% of failures: Complete scan failure - no devices found
                    self.availableDevices = []
                    self.lastError = .scanningFailed
                    
                    scanSpan?.setData(value: 0, key: "devices_found")
                    scanSpan?.setTag(value: "failure", key: "scan_status")
                    scanSpan?.setTag(value: "no_devices", key: "failure_reason")
                    scanSpan?.setTag(value: "bluetooth_timeout", key: "scan_result")
                    
                    SentrySDK.capture(error: BluetoothError.scanningFailed)
                    print("❌ Bluetooth scan failed - no devices found")
                    
                } else if failureType < 0.6 {
                    // 30% of failures: Partial scan - only find 1-2 devices
                    let fullDevices = BluetoothDevice.generateSampleDevices()
                    let partialCount = Int.random(in: 1...2)
                    self.availableDevices = Array(fullDevices.prefix(partialCount))
                    
                    scanSpan?.setData(value: self.availableDevices.count, key: "devices_found")
                    scanSpan?.setTag(value: "partial", key: "scan_status")
                    scanSpan?.setTag(value: "incomplete_discovery", key: "failure_reason")
                    scanSpan?.setTag(value: "degraded_signal", key: "scan_result")
                    
                    print("⚠️ Bluetooth scan partially failed - only found \(self.availableDevices.count) devices")
                    
                } else {
                    // 40% of failures: Scan timeout - return cached/stale devices
                    let staleDevices = BluetoothDevice.generateSampleDevices().map { device in
                        BluetoothDevice(
                            name: device.name,
                            deviceType: device.deviceType,
                            signalStrength: max(20, device.signalStrength - 30), // Weaker signals
                            isConnected: false,
                            batteryLevel: device.batteryLevel,
                            lastSeen: Date().addingTimeInterval(-600) // 10 minutes ago
                        )
                    }
                    let staleCount = Int.random(in: 2...3)
                    self.availableDevices = Array(staleDevices.prefix(staleCount))
                    self.lastError = .connectionTimeout
                    
                    scanSpan?.setData(value: self.availableDevices.count, key: "devices_found")
                    scanSpan?.setTag(value: "timeout", key: "scan_status")
                    scanSpan?.setTag(value: "scan_timeout", key: "failure_reason")
                    scanSpan?.setTag(value: "stale_cache", key: "scan_result")
                    scanSpan?.setTag(value: "true", key: "using_cached_results")
                    
                    print("⏱️ Bluetooth scan timed out - using cached devices (\(self.availableDevices.count) found)")
                }
            }
            
            scanSpan?.setData(value: Int(scanDelay * 1000), key: "scan_duration_ms")
            scanSpan?.finish()
            
            // Add appropriate breadcrumbs for different outcomes
            if scanOutcome > 0.5 {
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .info,
                    category: "bluetooth.scan.success"
                ))
            } else {
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .warning,
                    category: "bluetooth.scan.failure"
                ))
            }
        }
    }
    
    func connectToDevice(_ device: BluetoothDevice) {
        connectionState = .connecting
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.connection"
        ))
        
        // Create connection span as part of the active session
        let connectionSpan = SessionManager.shared.createBluetoothSpan(
            operation: "connection",
            description: "Connect to Bluetooth Device: \(device.name)",
            deviceName: device.name
        )
        connectionSpan?.setTag(value: device.name, key: "device_name")
        connectionSpan?.setTag(value: device.deviceType.rawValue, key: "device_type")
        connectionSpan?.setData(value: device.signalStrength, key: "signal_strength")
        connectionSpan?.setTag(value: "true", key: "is_user_action")
        
        // 🎯 DEMO: Create poor connection rates for specific devices
        let willSucceed: Bool
        switch device.name {
        case "Bedroom Move":
            // 40% success rate - This will drag overall success below 85%
            willSucceed = Double.random(in: 0...1) > 0.6
        case "Basement Sub":
            // 70% success rate - Also contribute to poor metrics
            willSucceed = Double.random(in: 0...1) > 0.3
        default:
            // Other devices maintain 95% success rate
            willSucceed = Double.random(in: 0...1) > 0.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Track UI state render for connection result as child of connection span
            let renderSpan = connectionSpan?.startChild(
                operation: "ui.state.render", 
                description: "Update connection UI state"
            )
            renderSpan?.setTag(value: "connection_result", key: "state_change")
            renderSpan?.setTag(value: device.name, key: "device_name")
            
            if willSucceed {
                self.connectedDevice = device
                self.connectionState = .connected
                self.lastError = nil
                renderSpan?.setTag(value: "success", key: "connection_status")
                // Set connection result for success rate metric
                connectionSpan?.setTag(value: "success", key: "connection_result")
                connectionSpan?.setTag(value: "connected", key: "final_state")
                
                print("✅ Device connected successfully: \(device.name)")
            } else {
                self.connectionState = .failed
                self.lastError = .connectionTimeout
                renderSpan?.setTag(value: "failed", key: "connection_status")
                // Set connection result for success rate metric
                connectionSpan?.setTag(value: "failure", key: "connection_result")
                connectionSpan?.setTag(value: "timeout", key: "failure_reason")
                
                SentrySDK.capture(error: BluetoothError.connectionTimeout)
                
                print("❌ Device connection failed: \(device.name)")
            }
            
            renderSpan?.finish()
            connectionSpan?.finish()
        }
    }
    
    func disconnectFromDevice() {
        guard let device = connectedDevice else { return }
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.disconnection"
        ))
        
        connectedDevice = nil
        connectionState = .disconnected
    }
    
    func refreshDevices() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.refresh"
        ))
        
        availableDevices = BluetoothDevice.generateSampleDevices()
    }
    
    func sendBLECommand(_ command: String, parameters: [String: Any] = [:]) async throws -> [String: Any] {
        guard let device = connectedDevice else {
            throw BluetoothError.deviceNotFound
        }

        // Create BLE command span as part of the active session
        let commandSpan = SessionManager.shared.createBluetoothSpan(
            operation: "write.command",
            description: "BLE Command: \(command)",
            deviceName: device.name
        )
        commandSpan?.setTag(value: command, key: "command_type")
        commandSpan?.setTag(value: device.name, key: "device_name")
        commandSpan?.setTag(value: device.id.uuidString, key: "device_id")
        commandSpan?.setTag(value: device.deviceType.rawValue, key: "device_type")
        commandSpan?.setData(value: device.signalStrength, key: "signal_strength")
        commandSpan?.setTag(value: "true", key: "is_user_action")
        
        // Mobile Performance: Network-like characteristics
        commandSpan?.setTag(value: "bluetooth", key: "network_type")
        commandSpan?.setTag(value: "2.4GHz", key: "frequency_band")
        
        // Add battery level if available (for portable devices)
        if let batteryLevel = device.batteryLevel {
            commandSpan?.setData(value: batteryLevel, key: "battery_level")
        }

        // Mobile Vitals: Network request breadcrumb
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "mobile.network"
        ))

        do {
            // Simulate BLE write operation with realistic timing
            let writeLatency = Double.random(in: 15...80) // BLE write: 15-80ms
            let ackLatency = Double.random(in: 20...120)  // Device ACK: 20-120ms
            let willSucceed = Double.random(in: 0...1) > 0.05  // 95% success rate

            // Phase 1: BLE Write (simulates network request)
            let writeStartTime = Date()
            try await Task.sleep(nanoseconds: UInt64(writeLatency * 1_000_000))
            
            if !willSucceed {
                commandSpan?.setTag(value: "failed", key: "command_status")
                commandSpan?.setData(value: writeLatency, key: "write_latency_ms")
                commandSpan?.setTag(value: "timeout", key: "failure_reason")
                commandSpan?.finish()
                
                // Mobile Performance: Track failed requests
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .error,
                    category: "mobile.network.error"
                ))
                
                throw BluetoothError.commandFailed(command)
            }

            // Phase 2: Device Response as child of command span
            let responseSpan = commandSpan?.startChild(
                operation: "device.response", 
                description: "Device ACK: \(command)"
            )
            responseSpan?.setTag(value: device.deviceType.rawValue, key: "device_type")
            responseSpan?.setTag(value: "bluetooth_ack", key: "response_type")
            
            try await Task.sleep(nanoseconds: UInt64(ackLatency * 1_000_000))
            
            let totalLatency = writeLatency + ackLatency
            let writeEndTime = Date()
            let requestDuration = writeEndTime.timeIntervalSince(writeStartTime) * 1000
            
            // Tag spans with Mobile Performance metrics
            commandSpan?.setTag(value: "success", key: "command_status")
            commandSpan?.setData(value: writeLatency, key: "write_latency_ms")
            commandSpan?.setData(value: totalLatency, key: "total_latency_ms")
            commandSpan?.setData(value: requestDuration, key: "request_duration_ms")
            
            responseSpan?.setData(value: ackLatency, key: "ack_latency_ms")
            responseSpan?.setTag(value: "received", key: "ack_status")
            responseSpan?.setData(value: 200, key: "status_code") // Simulate HTTP-like status
            
            // Return simulated device response with performance metrics
            let response = [
                "status": "success",
                "command": command,
                "latency_ms": totalLatency,
                "device_state": ["volume": 75, "track": "Updated Track"],
                "write_latency_ms": writeLatency,
                "ack_latency_ms": ackLatency,
                "request_duration_ms": requestDuration
            ] as [String : Any]
            
            responseSpan?.finish()
            commandSpan?.finish()
            
            // Mobile Performance: Successful request breadcrumb
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "mobile.network.success"
            ))
            
            print("✅ BLE Command '\(command)' completed successfully in \(totalLatency)ms")
            return response

        } catch {
            commandSpan?.setTag(value: "error", key: "command_status")
            commandSpan?.setTag(value: error.localizedDescription, key: "error_message")
            commandSpan?.finish()
            
            // Mobile Performance: Error tracking
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .error,
                category: "mobile.network.error"
            ))
            
            SentrySDK.capture(error: error)
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialDevices() {
        availableDevices = BluetoothDevice.generateSampleDevices()
    }
} 
