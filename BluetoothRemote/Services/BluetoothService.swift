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
        
        // Simulate device discovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isScanning = false
            self.availableDevices = BluetoothDevice.generateSampleDevices()
            
            scanSpan?.setTag(value: "\(self.availableDevices.count)", key: "devices_found")
            scanSpan?.setTag(value: "completed", key: "scan_status")
            scanSpan?.finish()
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
        connectionSpan?.setTag(value: "\(device.signalStrength)", key: "signal_strength")
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
        commandSpan?.setTag(value: "\(device.signalStrength)", key: "signal_strength")
        commandSpan?.setTag(value: "true", key: "is_user_action")
        
        // Mobile Performance: Network-like characteristics
        commandSpan?.setTag(value: "bluetooth", key: "network_type")
        commandSpan?.setTag(value: "2.4GHz", key: "frequency_band")
        
        // Add battery level if available (for portable devices)
        if let batteryLevel = device.batteryLevel {
            commandSpan?.setTag(value: "\(batteryLevel)", key: "battery_level")
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
                commandSpan?.setTag(value: "\(writeLatency)", key: "write_latency_ms")
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
            commandSpan?.setTag(value: "\(writeLatency)", key: "write_latency_ms")
            commandSpan?.setTag(value: "\(totalLatency)", key: "total_latency_ms")
            commandSpan?.setTag(value: "\(requestDuration)", key: "request_duration_ms")
            
            responseSpan?.setTag(value: "\(ackLatency)", key: "ack_latency_ms")
            responseSpan?.setTag(value: "received", key: "ack_status")
            responseSpan?.setTag(value: "200", key: "status_code") // Simulate HTTP-like status
            
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
