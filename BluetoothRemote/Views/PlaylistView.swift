import SwiftUI
import Sentry

struct PlaylistView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
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
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "ui.navigation"
            ))
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
                    let span = SentrySDK.span?.startChild(operation: "user.action.shuffle", description: "Shuffle Playlist")
                    span?.setTag(value: "\(audioPlayer.isShuffled)", key: "shuffle_enabled")
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
                    let transaction = SentrySDK.startTransaction(name: "Shuffle Playlist", operation: "user.action.shuffle")
                    audioPlayer.shufflePlaylist()
                    transaction.setTag(value: "user_initiated", key: "shuffle_source")
                    transaction.finish()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func selectTrack(at index: Int) {
        guard index < audioPlayer.currentPlaylist.count else { return }
        
        let span = SentrySDK.span?.startChild(operation: "user.action.track_select", description: "Select Track")
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