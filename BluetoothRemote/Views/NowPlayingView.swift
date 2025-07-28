import SwiftUI
import Sentry

struct NowPlayingView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @EnvironmentObject var bluetoothService: BluetoothService
    @State private var isDraggingSeeker = false
    @State private var seekerValue: Double = 0
    @State private var showingEQSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Connection Status
                    connectionStatusCard
                    
                    // Album Artwork
                    albumArtworkView(size: min(geometry.size.width * 0.8, 300))
                    
                    // Track Information
                    trackInformationView
                    
                    // Progress Bar
                    progressBarView
                    
                    // Playback Controls
                    playbackControlsView
                    
                    // Volume Control
                    volumeControlView
                    
                    // EQ and Settings
                    audioSettingsView
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .onAppear {
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "ui.navigation"
            ))
        }
    }
    
    private var connectionStatusCard: some View {
        Group {
            if let connectedDevice = bluetoothService.connectedDevice {
                HStack {
                    Image(systemName: connectedDevice.deviceType.icon)
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading) {
                        Text("Connected to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(connectedDevice.name)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Signal strength indicator
                    HStack(spacing: 1) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 3, height: CGFloat(4 + index * 2))
                                .foregroundColor(signalColor(for: index, strength: connectedDevice.signalStrength))
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("No device connected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func albumArtworkView(size: CGFloat) -> some View {
        ZStack {
            // Placeholder artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            
            // Music note icon
            Image(systemName: "music.note")
                .font(.system(size: size * 0.25))
                .foregroundColor(.white.opacity(0.8))
        }
        .shadow(radius: 10)
    }
    
    private var trackInformationView: some View {
        VStack(spacing: 8) {
            if let track = audioPlayer.currentTrack {
                Text(track.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(track.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let album = track.album {
                    Text(album)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("No track selected")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Choose a track from your playlist")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressBarView: some View {
        VStack(spacing: 8) {
            // Progress slider
            Slider(
                value: $seekerValue,
                in: 0...(audioPlayer.currentTrack?.duration ?? 1),
                onEditingChanged: { editing in
                    isDraggingSeeker = editing
                    if !editing {
                        // Seek to new position when user finishes dragging
                        let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Audio Seek")
                        span?.setTag(value: "audio.seek", key: "control_type")
                        span?.setTag(value: "50", key: "ui_response_threshold_ms")
                        span?.setTag(value: "\(seekerValue)", key: "seek_time")
                        audioPlayer.seekTo(seekerValue)
                        span?.finish()
                    }
                }
            )
            .accentColor(.blue)
            .onReceive(audioPlayer.$currentTime) { currentTime in
                if !isDraggingSeeker {
                    seekerValue = currentTime
                }
            }
            
            // Time labels
            HStack {
                Text(formatTime(seekerValue))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(audioPlayer.currentTrack?.duration ?? 0))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var playbackControlsView: some View {
        HStack(spacing: 40) {
            // Previous Track
                         Button(action: {
                 let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Skip Previous")
                 span?.setTag(value: "audio.control.previous", key: "control_type")
                 span?.setTag(value: "50", key: "ui_response_threshold_ms")
                 audioPlayer.skipToPrevious()
                 span?.finish()
             }) {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }
            
            // Play/Pause
                         Button(action: {
                 let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Play/Pause Control")
                 span?.setTag(value: "audio.control.playpause", key: "control_type")
                 span?.setTag(value: "50", key: "ui_response_threshold_ms") // For ui.block_ms metric
                 
                 switch audioPlayer.playbackState {
                 case .playing:
                     audioPlayer.pause()
                     span?.setTag(value: "pause", key: "action")
                 case .paused, .stopped:
                     audioPlayer.play()
                     span?.setTag(value: "play", key: "action")
                 case .loading:
                     break // Do nothing while loading
                 }
                 
                 span?.finish()
             }) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 64, height: 64)
                    
                    if audioPlayer.playbackState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: audioPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(audioPlayer.playbackState == .loading)
            
            // Next Track
                         Button(action: {
                 let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Skip Next")
                 span?.setTag(value: "audio.control.next", key: "control_type")
                 span?.setTag(value: "50", key: "ui_response_threshold_ms")
                 audioPlayer.skipToNext()
                 span?.finish()
             }) {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var volumeControlView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Toggle mute from now playing")
                    span?.setTag(value: "audio.mute.toggle", key: "control_type")
                    span?.setTag(value: "50", key: "ui_response_threshold_ms")
                    audioPlayer.toggleMute()
                    span?.finish()
                }) {
                    Image(systemName: audioPlayer.audioSettings.muteEnabled ? "speaker.slash" : "speaker.2")
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Image(systemName: "speaker")
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { audioPlayer.audioSettings.volume },
                        set: { newValue in
                            let span = SentrySDK.span?.startChild(operation: "ui.action.remoteControl", description: "Volume adjustment")
                            span?.setTag(value: "audio.volume.adjust", key: "control_type")
                            span?.setTag(value: "50", key: "ui_response_threshold_ms")
                            audioPlayer.adjustVolume(newValue)
                            span?.setTag(value: "\(newValue)", key: "volume_level")
                            span?.finish()
                        }
                    ),
                    in: 0...1
                )
                .accentColor(.blue)
                
                Image(systemName: "speaker.2")
                    .foregroundColor(.secondary)
            }
            
            Text("\(Int(audioPlayer.audioSettings.volume * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var audioSettingsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Audio Settings")
                    .font(.headline)
                
                Spacer()
                
                Button("EQ Presets") {
                    let span = SentrySDK.span?.startChild(operation: "ui.sheet.eq", description: "Show EQ presets")
                    showingEQSheet = true
                    span?.finish()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Bass Control
            VStack {
                HStack {
                    Text("Bass")
                        .font(.subheadline)
                    Spacer()
                    Text("\(audioPlayer.audioSettings.bass > 0 ? "+" : "")\(Int(audioPlayer.audioSettings.bass * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { audioPlayer.audioSettings.bass },
                        set: { newValue in
                            let span = SentrySDK.span?.startChild(operation: "audio.eq.bass", description: "Bass adjustment")
                            audioPlayer.adjustBass(newValue)
                            span?.finish()
                        }
                    ),
                    in: -1...1
                )
                .accentColor(.orange)
            }
            
            // Treble Control
            VStack {
                HStack {
                    Text("Treble")
                        .font(.subheadline)
                    Spacer()
                    Text("\(audioPlayer.audioSettings.treble > 0 ? "+" : "")\(Int(audioPlayer.audioSettings.treble * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { audioPlayer.audioSettings.treble },
                        set: { newValue in
                            let span = SentrySDK.span?.startChild(operation: "audio.eq.treble", description: "Treble adjustment")
                            audioPlayer.adjustTreble(newValue)
                            span?.finish()
                        }
                    ),
                    in: -1...1
                )
                .accentColor(.green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingEQSheet) {
            EQPresetSheet(audioPlayer: audioPlayer)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func signalColor(for index: Int, strength: Int) -> Color {
        let strengthLevel = strength / 25
        return index < strengthLevel ? .green : .gray.opacity(0.3)
    }
}

// MARK: - EQ Preset Sheet

struct EQPresetSheet: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AudioSettings.EQPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        let span = SentrySDK.span?.startChild(operation: "audio.eq.preset.apply", description: "Apply EQ Preset")
                        span?.setTag(value: preset.displayName, key: "preset_name")
                        audioPlayer.applyEQPreset(preset)
                        span?.finish()
                        
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                let settings = preset.settings
                                Text("Bass: \(settings.bass > 0 ? "+" : "")\(Int(settings.bass * 100)), Treble: \(settings.treble > 0 ? "+" : "")\(Int(settings.treble * 100))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if audioPlayer.audioSettings.bass == preset.settings.bass &&
                               audioPlayer.audioSettings.treble == preset.settings.treble {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("EQ Presets")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        let bluetoothService = BluetoothService()
        let audioPlayer = AudioPlayerService(bluetoothService: bluetoothService)
        
        return NowPlayingView(audioPlayer: audioPlayer)
            .environmentObject(bluetoothService)
    }
} 