import Foundation
import Combine
import Sentry

@MainActor
class AudioPlayerService: ObservableObject {
    @Published var currentPlaylist: [AudioTrack] = []
    @Published var currentTrackIndex: Int = 0
    @Published var currentTime: TimeInterval = 0
    @Published var playbackState: PlaybackState = .stopped
    @Published var audioSettings = AudioSettings()
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled: Bool = false
    
    // Bluetooth service reference for command execution
    private let bluetoothService: BluetoothService
    
    // Private Properties
    private var playbackTimer: Timer?
    private let totalTime: TimeInterval = 180 // 3 minutes per track
    
    enum PlaybackState: String, CaseIterable {
        case stopped = "stopped"
        case playing = "playing"
        case paused = "paused"
        case loading = "loading"
        
        var icon: String {
            switch self {
            case .stopped: return "stop.fill"
            case .playing: return "pause.fill"
            case .paused: return "play.fill"
            case .loading: return "ellipsis"
            }
        }
    }
    
    enum RepeatMode: String, CaseIterable {
        case off = "off"
        case one = "one"
        case all = "all"
        
        var icon: String {
            switch self {
            case .off: return "repeat"
            case .one: return "repeat.1"
            case .all: return "repeat"
            }
        }
    }
    
    enum PlaybackError: Error, LocalizedError {
        case noTrackSelected
        case deviceNotConnected
        case playbackFailed(String)
        case commandTimeout
        
        var errorDescription: String? {
            switch self {
            case .noTrackSelected: return "No track selected for playback"
            case .deviceNotConnected: return "No device connected"
            case .playbackFailed(let reason): return "Playback failed: \(reason)"
            case .commandTimeout: return "Audio command timed out"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
        
        // Track service initialization performance
        let initSpan = SentrySDK.span?.startChild(operation: "service.init", description: "AudioPlayerService Initialization")
        initSpan?.setTag(value: "AudioPlayerService", key: "service_name")
        
        setupInitialPlaylist()
        startPlaybackTimer()
        
        // Track initialization completion
        initSpan?.setTag(value: "success", key: "init_status")
        initSpan?.finish()
        
        // Add mobile vitals breadcrumb
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "mobile.performance"
        ))
    }
    
    deinit {
        playbackTimer?.invalidate()
    }
    
    // MARK: - Computed Properties
    
    var currentTrack: AudioTrack? {
        guard currentTrackIndex < currentPlaylist.count else { return nil }
        return currentPlaylist[currentTrackIndex]
    }
    
    var progress: Double {
        return totalTime > 0 ? currentTime / totalTime : 0
    }
    
    // MARK: - Core Playback Controls
    
    func play() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.control"
        ))
        
        Task {
            do {
                guard let track = currentTrack else {
                    throw PlaybackError.noTrackSelected
                }
                
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                // Send BLE command to device
                let response = try await bluetoothService.sendBLECommand("PLAY", parameters: [
                    "track_id": track.id.uuidString,
                    "position": currentTime
                ])
                
                // Track UI state render after BLE response as child of current active span
                let renderSpan = SentrySDK.span?.startChild(
                    operation: "ui.state.render", 
                    description: "Update playback UI state"
                )
                renderSpan?.setTag(value: "play", key: "state_change")
                renderSpan?.setTag(value: track.title, key: "track_title")
                renderSpan?.setTag(value: "true", key: "is_mobile_vital")
                renderSpan?.finish()
                
                // Update UI state
                playbackState = .playing
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func pause() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.control"
        ))
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let response = try await bluetoothService.sendBLECommand("PAUSE")
                
                // Track UI state render after BLE response as child of current active span
                let renderSpan = SentrySDK.span?.startChild(
                    operation: "ui.state.render", 
                    description: "Update pause UI state"
                )
                renderSpan?.setTag(value: "pause", key: "state_change")
                renderSpan?.setTag(value: "true", key: "is_mobile_vital")
                renderSpan?.finish()
                
                playbackState = .paused
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func stop() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.control"
        ))
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let _ = try await bluetoothService.sendBLECommand("STOP")
                playbackState = .stopped
                currentTime = 0
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func skipToNext() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.navigation"
        ))
        
        guard !currentPlaylist.isEmpty else { return }
        
        // 🎯 DEMO: Add artificial lag for specific devices
        let deviceName = bluetoothService.connectedDevice?.name ?? ""
        let artificialDelay: TimeInterval
        
        switch deviceName {
        case "Basement Sub":
            artificialDelay = 0.15 // 150ms delay - will show as laggy
        case "Kitchen One":
            artificialDelay = 0.12 // 120ms delay - also laggy
        default:
            artificialDelay = 0.02 // Normal 20ms delay
        }
        
        // Create performance tracking span
        let skipSpan = SentrySDK.span?.startChild(
            operation: "ui.action.remoteControl",
            description: "Skip Next"
        )
        skipSpan?.setTag(value: "audio.control.next", key: "control_type")
        skipSpan?.setTag(value: deviceName, key: "device_name")
        
        // Simulate the artificial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + artificialDelay) {
            let nextIndex = self.getNextTrackIndex()
            if nextIndex != self.currentTrackIndex {
                self.currentTrackIndex = nextIndex
                self.currentTime = 0
                
                if self.playbackState == .playing {
                    self.play()
                }
            }
            skipSpan?.finish()
        }
    }
    
    func skipToPrevious() {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.navigation"
        ))
        
        guard !currentPlaylist.isEmpty else { return }
        
        // 🎯 DEMO: Add artificial lag for specific devices
        let deviceName = bluetoothService.connectedDevice?.name ?? ""
        let artificialDelay: TimeInterval
        
        switch deviceName {
        case "Basement Sub":
            artificialDelay = 0.18 // 180ms delay - very laggy
        case "Kitchen One":
            artificialDelay = 0.14 // 140ms delay - also laggy
        default:
            artificialDelay = 0.025 // Normal 25ms delay
        }
        
        // Create performance tracking span
        let skipSpan = SentrySDK.span?.startChild(
            operation: "ui.action.remoteControl",
            description: "Skip Previous"
        )
        skipSpan?.setTag(value: "audio.control.previous", key: "control_type")
        skipSpan?.setTag(value: deviceName, key: "device_name")
        
        // Simulate the artificial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + artificialDelay) {
            let prevIndex = self.getPreviousTrackIndex()
            self.currentTrackIndex = prevIndex
            self.currentTime = 0
            
            if self.playbackState == .playing {
                self.play()
            }
            skipSpan?.finish()
        }
    }
    
    func seekTo(_ time: TimeInterval) {
        let clampedTime = max(0, min(time, totalTime))
        currentTime = clampedTime
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let _ = try await bluetoothService.sendBLECommand("SEEK", parameters: ["position": time])
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func adjustVolume(_ volume: Double) {
        let clampedVolume = max(0.0, min(1.0, volume))
        audioSettings.volume = clampedVolume
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let response = try await bluetoothService.sendBLECommand("VOLUME", parameters: ["level": volume])
                
                // Track UI state render for volume update as child of current active span
                let renderSpan = SentrySDK.span?.startChild(
                    operation: "ui.state.render", 
                    description: "Update volume UI state"
                )
                renderSpan?.setTag(value: "volume_change", key: "state_change")
                renderSpan?.setTag(value: "\(Int(clampedVolume * 100))", key: "volume_percent")
                renderSpan?.setTag(value: "true", key: "is_mobile_vital")
                renderSpan?.finish()
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func adjustBass(_ bass: Double) {
        let clampedBass = max(-1.0, min(1.0, bass))
        audioSettings.bass = clampedBass
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let response = try await bluetoothService.sendBLECommand("EQ_BASS", parameters: ["level": bass])
                
                // Track UI state render for EQ update as child of current active span
                let renderSpan = SentrySDK.span?.startChild(
                    operation: "ui.state.render", 
                    description: "Update EQ UI state"
                )
                renderSpan?.setTag(value: "eq_bass", key: "state_change")
                renderSpan?.setTag(value: "\(Int(clampedBass * 100))", key: "bass_level")
                renderSpan?.setTag(value: "true", key: "is_mobile_vital")
                renderSpan?.finish()
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func adjustTreble(_ treble: Double) {
        let clampedTreble = max(-1.0, min(1.0, treble))
        audioSettings.treble = clampedTreble
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let _ = try await bluetoothService.sendBLECommand("EQ_TREBLE", parameters: ["level": treble])
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func applyEQPreset(_ preset: AudioSettings.EQPreset) {
        // Note: Set preset values directly since selectedPreset is not stored
        
        // Apply preset values
        switch preset {
        case .flat:
            audioSettings.bass = 0.0
            audioSettings.treble = 0.0
        case .bass:
            audioSettings.bass = 0.5
            audioSettings.treble = 0.0
        case .rock:
            audioSettings.bass = 0.3
            audioSettings.treble = 0.2
        case .jazz:
            audioSettings.bass = -0.1
            audioSettings.treble = 0.1
        case .classical:
            audioSettings.bass = -0.2
            audioSettings.treble = 0.3
        case .electronic:
            audioSettings.bass = 0.4
            audioSettings.treble = 0.1
        case .vocal:
            audioSettings.bass = -0.1
            audioSettings.treble = 0.4
        }
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let _ = try await bluetoothService.sendBLECommand("EQ_PRESET", parameters: [
                    "preset": preset.rawValue,
                    "bass": audioSettings.bass,
                    "treble": audioSettings.treble
                ])
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func toggleMute() {
        audioSettings.muteEnabled.toggle()
        
        Task {
            do {
                guard bluetoothService.connectedDevice != nil else {
                    throw PlaybackError.deviceNotConnected
                }
                
                let _ = try await bluetoothService.sendBLECommand("MUTE", parameters: ["enabled": audioSettings.muteEnabled])
                
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
    
    func selectTrack(at index: Int) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.navigation"
        ))
        
        guard index >= 0 && index < currentPlaylist.count else { return }
        
        let _ = currentPlaylist[index]
        currentTrackIndex = index
        currentTime = 0
        
        if playbackState == .playing {
            play()
        }
    }
    
    func shufflePlaylist() {
        isShuffled.toggle()
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "audio.playback"
        ))
        
        // 🎯 DEMO: Add artificial lag for specific devices during shuffle
        let deviceName = bluetoothService.connectedDevice?.name ?? ""
        let artificialDelay: TimeInterval
        
        switch deviceName {
        case "Basement Sub":
            artificialDelay = 0.25 // 250ms delay - very laggy for shuffle
        case "Kitchen One":
            artificialDelay = 0.20 // 200ms delay - also very laggy
        default:
            artificialDelay = 0.03 // Normal 30ms delay
        }
        
        // Create performance tracking span for shuffle
        let shuffleSpan = SentrySDK.span?.startChild(
            operation: "ui.action.remoteControl",
            description: "Shuffle Playlist"
        )
        shuffleSpan?.setTag(value: "playlist.shuffle", key: "control_type")
        shuffleSpan?.setTag(value: deviceName, key: "device_name")
        shuffleSpan?.setTag(value: "\(isShuffled)", key: "shuffle_enabled")
        
        // Simulate the artificial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + artificialDelay) {
            if self.isShuffled {
                self.currentPlaylist.shuffle()
            } else {
                self.currentPlaylist = AudioTrack.generateSampleTracks()
            }
            
            // Reset to first track
            self.currentTrackIndex = 0
            self.currentTime = 0
            
            shuffleSpan?.finish()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialPlaylist() {
        currentPlaylist = AudioTrack.generateSampleTracks()
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackTime()
            }
        }
    }
    
    private func updatePlaybackTime() {
        guard playbackState == .playing else { return }
        
        currentTime += 1.0
        
        if currentTime >= totalTime {
            handleTrackEnded()
        }
    }
    
    private func handleTrackEnded() {
        switch repeatMode {
        case .one:
            currentTime = 0
            play()
        case .all:
            skipToNext()
        case .off:
            if currentTrackIndex < currentPlaylist.count - 1 {
                skipToNext()
            } else {
                stop()
            }
        }
    }
    
    private func getNextTrackIndex() -> Int {
        guard !currentPlaylist.isEmpty else { return 0 }
        
        if currentTrackIndex < currentPlaylist.count - 1 {
            return currentTrackIndex + 1
        } else {
            return repeatMode == .all ? 0 : currentTrackIndex
        }
    }
    
    private func getPreviousTrackIndex() -> Int {
        guard !currentPlaylist.isEmpty else { return 0 }
        
        if currentTrackIndex > 0 {
            return currentTrackIndex - 1
        } else {
            return repeatMode == .all ? currentPlaylist.count - 1 : 0
        }
    }
} 