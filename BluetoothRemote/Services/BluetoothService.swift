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
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.scan"
        ))
        
        // Simulate device discovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isScanning = false
            self.availableDevices = BluetoothDevice.generateSampleDevices()
        }
    }
    
    func connectToDevice(_ device: BluetoothDevice) {
        // Start connection transaction (required for bt.pairing.success_rate metric)
        let connectionTransaction = SentrySDK.startTransaction(
            name: "Connect to Bluetooth Device",
            operation: "bt.connection"
        )
        connectionTransaction.setTag(value: device.name, key: "device_name")
        connectionTransaction.setTag(value: device.deviceType.rawValue, key: "device_type")
        connectionTransaction.setTag(value: "\(device.signalStrength)", key: "signal_strength")
        
        connectionState = .connecting
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.connection"
        ))
        
        // Simulate connection attempt
        let willSucceed = Double.random(in: 0...1) > 0.1 // 90% success rate
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Track UI state render for connection result
            let renderSpan = SentrySDK.span?.startChild(operation: "ui.state.render", description: "Update connection UI state")
            renderSpan?.setTag(value: "connection_result", key: "state_change")
            renderSpan?.setTag(value: device.name, key: "device_name")
            
            if willSucceed {
                self.connectedDevice = device
                self.connectionState = .connected
                self.lastError = nil
                renderSpan?.setTag(value: "success", key: "connection_status")
                // Set connection result for success rate metric
                connectionTransaction.setTag(value: "success", key: "connection_result")
            } else {
                self.connectionState = .failed
                self.lastError = .connectionTimeout
                renderSpan?.setTag(value: "failed", key: "connection_status")
                // Set connection result for success rate metric
                connectionTransaction.setTag(value: "failure", key: "connection_result")
                SentrySDK.capture(error: BluetoothError.connectionTimeout)
            }
            
            renderSpan?.finish()
            connectionTransaction.finish()
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

        // Start BLE command span (parent for the entire command flow)
        let commandSpan = SentrySDK.span?.startChild(operation: "bt.write.command", description: "BLE Command: \(command)")
        commandSpan?.setTag(value: command, key: "command_type")
        commandSpan?.setTag(value: device.name, key: "device_name")
        commandSpan?.setTag(value: device.id.uuidString, key: "device_id")
        commandSpan?.setTag(value: device.deviceType.rawValue, key: "device_type")
        commandSpan?.setTag(value: "\(device.signalStrength)", key: "signal_strength")
        
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

            // Phase 2: Device Response (simulates network response)
            let responseSpan = commandSpan?.startChild(operation: "device.response", description: "Device ACK: \(command)")
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
