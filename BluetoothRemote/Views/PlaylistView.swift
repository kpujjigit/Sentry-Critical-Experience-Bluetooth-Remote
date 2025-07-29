import SwiftUI
import Sentry

struct PlaylistView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @EnvironmentObject var bluetoothService: BluetoothService
    @State private var showingShuffleConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            playlistHeader
            
            // Playlist
            List {
                ForEach(Array(audioPlayer.currentPlaylist.enumerated()), id: \.element.id) { index, track in
                    TrackRowView(
                        track: track,
                        trackIndex: index + 1,
                        isCurrentTrack: index == audioPlayer.currentTrackIndex,
                        isPlaying: audioPlayer.playbackState == .playing && index == audioPlayer.currentTrackIndex
                    ) {
                        selectTrack(at: index)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            // Create screen load span as part of the active session
            let screenLoadSpan = SessionManager.shared.createScreenLoadSpan(screenName: "PlaylistView")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "ui.navigation"
            ))
            
            // Finish screen load span after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                screenLoadSpan?.setTag(value: "loaded", key: "load_status")
                screenLoadSpan?.finish()
            }
        }
    }
    
    private var playlistHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Your Playlist")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(audioPlayer.currentPlaylist.count) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // 🎯 DEMO: Track device-specific shuffle lag
                    let deviceName = bluetoothService.connectedDevice?.name ?? "No Device"
                    let expectedLag = (deviceName == "Basement Sub" || deviceName == "Kitchen One") ? 225 : 30
                    
                    let span = SessionManager.shared.createUserInteractionSpan(
                        action: "shuffle_button",
                        screen: "PlaylistView"
                    )
                    span?.setTag(value: "\(audioPlayer.isShuffled)", key: "shuffle_enabled")
                    span?.setTag(value: deviceName, key: "connected_device")
                    span?.setTag(value: "\(expectedLag)", key: "expected_lag_ms")
                    
                    showingShuffleConfirmation = true
                    span?.finish()
                }) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .alert(isPresented: $showingShuffleConfirmation) {
            Alert(
                title: Text("Shuffle Playlist"),
                message: Text("This will randomize the order of all tracks in your playlist."),
                primaryButton: .default(Text("Shuffle")) {
                    let span = SessionManager.shared.createUserInteractionSpan(
                        action: "shuffle_confirm",
                        screen: "PlaylistView"
                    )
                    span?.setTag(value: "user_initiated", key: "shuffle_source")
                    span?.setTag(value: "confirmation_dialog", key: "trigger_method")
                    
                    audioPlayer.shufflePlaylist()
                    span?.finish()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func selectTrack(at index: Int) {
        guard index < audioPlayer.currentPlaylist.count else { return }
        
        let span = SessionManager.shared.createUserInteractionSpan(
            action: "track_select",
            screen: "PlaylistView"
        )
        span?.setTag(value: "\(index)", key: "track_index")
        span?.setTag(value: "\(audioPlayer.playbackState == .playing)", key: "was_playing")
        
        audioPlayer.selectTrack(at: index)
        span?.finish()
    }
}

// MARK: - Track Row View

struct TrackRowView: View {
    let track: AudioTrack
    let trackIndex: Int
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Track Number or Playing Indicator
            ZStack {
                if isCurrentTrack && isPlaying {
                    PlaybackStateIndicator()
                } else {
                    Text("\(trackIndex)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 30)
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .fontWeight(isCurrentTrack ? .semibold : .medium)
                    .foregroundColor(isCurrentTrack ? .blue : .primary)
                
                HStack {
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let album = track.album {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(album)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Duration
            Text(formatDuration(track.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Playback State Indicator

struct PlaybackStateIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.blue)
                    .frame(width: 2, height: isAnimating ? CGFloat.random(in: 4...12) : 4)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        let bluetoothService = BluetoothService()
        let audioPlayer = AudioPlayerService(bluetoothService: bluetoothService)
        
        return PlaylistView(audioPlayer: audioPlayer)
    }
} 