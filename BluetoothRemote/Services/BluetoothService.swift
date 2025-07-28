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
            } else {
                self.connectionState = .failed
                self.lastError = .connectionTimeout
                renderSpan?.setTag(value: "failed", key: "connection_status")
                SentrySDK.capture(error: BluetoothError.connectionTimeout)
            }
            
            renderSpan?.finish()
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
        
        // Add battery level if available (for portable devices)
        if let batteryLevel = device.batteryLevel {
            commandSpan?.setTag(value: "\(batteryLevel)", key: "battery_level")
        }

        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "bluetooth.command"
        ))

        do {
            // Simulate BLE write operation with realistic timing
            let writeLatency = Double.random(in: 15...80) // BLE write: 15-80ms
            let ackLatency = Double.random(in: 20...120)  // Device ACK: 20-120ms
            let willSucceed = Double.random(in: 0...1) > 0.05  // 95% success rate

            // Phase 1: BLE Write
            try await Task.sleep(nanoseconds: UInt64(writeLatency * 1_000_000))
            
            if !willSucceed {
                commandSpan?.setTag(value: "failed", key: "command_status")
                commandSpan?.setTag(value: "writeLatency", key: "write_latency_ms")
                commandSpan?.finish()
                throw BluetoothError.commandFailed(command)
            }

            // Phase 2: Device Response
            let responseSpan = commandSpan?.startChild(operation: "device.response", description: "Device ACK: \(command)")
            responseSpan?.setTag(value: device.deviceType.rawValue, key: "device_type")
            
            try await Task.sleep(nanoseconds: UInt64(ackLatency * 1_000_000))
            
            let totalLatency = writeLatency + ackLatency
            
            // Tag spans with performance metrics
            commandSpan?.setTag(value: "success", key: "command_status")
            commandSpan?.setTag(value: "writeLatency", key: "write_latency_ms")
            commandSpan?.setTag(value: "totalLatency", key: "total_latency_ms")
            
            responseSpan?.setTag(value: "ackLatency", key: "ack_latency_ms")
            responseSpan?.setTag(value: "received", key: "ack_status")
            
            // Return simulated device response
            let response = [
                "status": "success",
                "command": command,
                "latency_ms": totalLatency,
                "device_state": ["volume": 75, "track": "Updated Track"],
                "write_latency_ms": writeLatency,
                "ack_latency_ms": ackLatency
            ] as [String : Any]
            
            responseSpan?.finish()
            commandSpan?.finish()
            
            return response

        } catch {
            commandSpan?.setTag(value: "error", key: "command_status")
            commandSpan?.finish()
            SentrySDK.capture(error: error)
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialDevices() {
        availableDevices = BluetoothDevice.generateSampleDevices()
    }
} 
