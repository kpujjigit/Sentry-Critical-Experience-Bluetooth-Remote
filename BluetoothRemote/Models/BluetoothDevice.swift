import Foundation
import Sentry

// MARK: - Bluetooth Device Models

struct BluetoothDevice: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let deviceType: DeviceType
    let signalStrength: Int // 0-100
    let isConnected: Bool
    let batteryLevel: Int? // For portable devices
    let lastSeen: Date
    
    enum DeviceType: String, CaseIterable {
        case speaker = "speaker"
        case soundbar = "soundbar"
        case homeTheater = "home_theater"
        case portable = "portable"
        case subwoofer = "subwoofer"
        
        var icon: String {
            switch self {
            case .speaker: return "hifispeaker"
            case .soundbar: return "tv"
            case .homeTheater: return "house"
            case .portable: return "airpods"
            case .subwoofer: return "waveform.circle"
            }
        }
        
        var displayName: String {
            switch self {
            case .speaker: return "Speaker"
            case .soundbar: return "Soundbar"
            case .homeTheater: return "Home Theater"
            case .portable: return "Portable"
            case .subwoofer: return "Subwoofer"
            }
        }
    }
    
    static func generateSampleDevices() -> [BluetoothDevice] {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "device.discovery"
        ))
        
        return [
            BluetoothDevice(
                name: "Living Room Arc",
                deviceType: .soundbar,
                signalStrength: 95,
                isConnected: false,
                batteryLevel: nil,
                lastSeen: Date()
            ),
            BluetoothDevice(
                name: "Kitchen One",
                deviceType: .speaker,
                signalStrength: 87,
                isConnected: false,
                batteryLevel: nil,
                lastSeen: Date().addingTimeInterval(-120)
            ),
            BluetoothDevice(
                name: "Bedroom Move",
                deviceType: .portable,
                signalStrength: 72,
                isConnected: false,
                batteryLevel: 78,
                lastSeen: Date().addingTimeInterval(-300)
            ),
            BluetoothDevice(
                name: "Office Era 100",
                deviceType: .speaker,
                signalStrength: 91,
                isConnected: false,
                batteryLevel: nil,
                lastSeen: Date().addingTimeInterval(-60)
            ),
            BluetoothDevice(
                name: "Basement Sub",
                deviceType: .subwoofer,
                signalStrength: 68,
                isConnected: false,
                batteryLevel: nil,
                lastSeen: Date().addingTimeInterval(-180)
            )
        ]
    }
}

// MARK: - Audio Content Models

struct AudioTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artwork: String? // Asset name or URL
    let genre: String?
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func generateSampleTracks() -> [AudioTrack] {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.content"
        ))
        
        return [
            AudioTrack(
                title: "Wireless Waves",
                artist: "Digital Sound Co.",
                album: "Tech Vibes",
                duration: 203,
                artwork: nil,
                genre: "Electronic"
            ),
            AudioTrack(
                title: "Bluetooth Blues",
                artist: "Connection Lost",
                album: "Signal Issues",
                duration: 178,
                artwork: nil,
                genre: "Blues"
            ),
            AudioTrack(
                title: "Streaming Dreams",
                artist: "Cloud Nine",
                album: "Remote Control",
                duration: 245,
                artwork: nil,
                genre: "Ambient"
            ),
            AudioTrack(
                title: "Bass Drop Protocol",
                artist: "Low Frequency Labs",
                album: "Subwoofer Sessions",
                duration: 189,
                artwork: nil,
                genre: "Dubstep"
            ),
            AudioTrack(
                title: "High Fidelity Morning",
                artist: "Audiophile's Choice",
                album: "Crystal Clear",
                duration: 267,
                artwork: nil,
                genre: "Jazz"
            )
        ]
    }
}

// MARK: - Playback State

enum PlaybackState: String, CaseIterable {
    case stopped = "stopped"
    case playing = "playing"
    case paused = "paused"
    case loading = "loading"
    case error = "error"
    
    var icon: String {
        switch self {
        case .stopped: return "stop.fill"
        case .playing: return "play.fill"
        case .paused: return "pause.fill"
        case .loading: return "arrow.clockwise"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Audio Settings

struct AudioSettings {
    var volume: Double = 0.5 // 0.0 to 1.0
    var bass: Double = 0.0 // -1.0 to 1.0
    var treble: Double = 0.0 // -1.0 to 1.0
    var balance: Double = 0.0 // -1.0 (left) to 1.0 (right)
    var loudness: Bool = false
    var muteEnabled: Bool = false
    
    // Custom EQ presets
    enum EQPreset: String, CaseIterable {
        case flat = "flat"
        case rock = "rock"
        case jazz = "jazz"
        case classical = "classical"
        case electronic = "electronic"
        case vocal = "vocal"
        case bass = "bass"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var settings: (bass: Double, treble: Double) {
            switch self {
            case .flat: return (0.0, 0.0)
            case .rock: return (0.3, 0.2)
            case .jazz: return (-0.1, 0.1)
            case .classical: return (-0.2, 0.3)
            case .electronic: return (0.4, 0.1)
            case .vocal: return (-0.1, 0.2)
            case .bass: return (0.6, -0.1)
            }
        }
    }
} 