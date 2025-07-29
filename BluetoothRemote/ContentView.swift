import SwiftUI
import Sentry

struct ContentView: View {
    @EnvironmentObject private var bluetoothService: BluetoothService
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab: MainTab = .devices
    @State private var showingDeviceSelection = false
    @State private var showingSettings = false
    @State private var showingConnectionError = false
    
    // MARK: - Helper Functions
    
    private func connectToDevice(_ device: BluetoothDevice) {
        let span = sessionManager.createUserInteractionSpan(
            action: "device_connection",
            screen: "DevicesView"
        )
        span?.setTag(value: device.name, key: "device_name")
        span?.setTag(value: device.deviceType.rawValue, key: "device_type")
        span?.setTag(value: "connection_attempt", key: "action_type")
        
        bluetoothService.connectToDevice(device)
        
        // Update session context after connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sessionManager.updateSessionContext(
                connectedDevice: bluetoothService.connectedDevice?.name,
                currentTrack: audioPlayer.currentTrack?.title,
                playbackState: audioPlayer.playbackState.rawValue
            )
            span?.finish()
        }
    }
    
    enum MainTab: String, CaseIterable {
        case devices = "devices"
        case nowPlaying = "now_playing"
        case playlist = "playlist"
        case settings = "settings"
        
        var title: String {
            switch self {
            case .devices: return "Devices"
            case .nowPlaying: return "Now Playing"
            case .playlist: return "Playlist"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .devices: return "speaker.2"
            case .nowPlaying: return "play.circle"
            case .playlist: return "music.note.list"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Status Bar
                topStatusBar
                
                // Main Content
                TabView(selection: $selectedTab) {
                    DevicesView(
                        bluetoothService: bluetoothService,
                        connectToDevice: connectToDevice
                    )
                        .tabItem {
                            Image(systemName: MainTab.devices.icon)
                            Text(MainTab.devices.title)
                        }
                        .tag(MainTab.devices)
                    
                    NowPlayingView(audioPlayer: audioPlayer)
                        .tabItem {
                            Image(systemName: MainTab.nowPlaying.icon)
                            Text(MainTab.nowPlaying.title)
                        }
                        .tag(MainTab.nowPlaying)
                    
                    PlaylistView(audioPlayer: audioPlayer)
                        .tabItem {
                            Image(systemName: MainTab.playlist.icon)
                            Text(MainTab.playlist.title)
                        }
                        .tag(MainTab.playlist)
                    
                    SettingsView(audioPlayer: audioPlayer)
                        .tabItem {
                            Image(systemName: MainTab.settings.icon)
                            Text(MainTab.settings.title)
                        }
                        .tag(MainTab.settings)
                }
                .accentColor(.primary)
                
                // Mini Player (when not on Now Playing tab)
                if selectedTab != .nowPlaying && audioPlayer.currentTrack != nil {
                    MiniPlayerView(audioPlayer: audioPlayer) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = .nowPlaying
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Create screen load span as part of the active session
            let screenLoadSpan = sessionManager.createScreenLoadSpan(screenName: "ContentView")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "ui.navigation"
            ))
            
            // Update session context with initial app state
            sessionManager.updateSessionContext(
                connectedDevice: bluetoothService.connectedDevice?.name,
                currentTrack: audioPlayer.currentTrack?.title,
                playbackState: audioPlayer.playbackState.rawValue
            )
            
            // Simulate TTFD for SwiftUI (since Sentry's TTFD only works for UIViewController)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                screenLoadSpan?.setTag(value: "loaded", key: "load_status")
                screenLoadSpan?.finish()
                SentrySDK.reportFullyDisplayed()
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Create tab navigation span as part of the active session
            let navigationSpan = sessionManager.createUserInteractionSpan(
                action: "tab_navigation",
                screen: "ContentView"
            )
            navigationSpan?.setTag(value: newTab.rawValue, key: "destination_tab")
            navigationSpan?.setTag(value: "tab_switch", key: "interaction_type")
            
            SentrySDK.addBreadcrumb(Breadcrumb(
                level: .info,
                category: "ui.navigation"
            ))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                navigationSpan?.finish()
            }
        }
    }
    
    private var topStatusBar: some View {
        HStack {
            // App Title
            Text("Bluetooth Remote")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Connection Status
            connectionStatusView
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 8) {
            if let connectedDevice = bluetoothService.connectedDevice {
                Image(systemName: connectedDevice.deviceType.icon)
                    .foregroundColor(.green)
                
                Text(connectedDevice.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                
                Text("Not Connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Devices View

struct DevicesView: View {
    @ObservedObject var bluetoothService: BluetoothService
    @State private var showingConnectionError = false
    let connectToDevice: (BluetoothDevice) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with scan button
            HStack {
                Text("Available Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    let span = SessionManager.shared.createUserInteractionSpan(
                        action: "device_scan",
                        screen: "DevicesView"
                    )
                    if !bluetoothService.isScanning {
                        bluetoothService.startScanning()
                    }
                    span?.setTag(value: "start", key: "scan_action")
                    span?.finish()
                }) {
                    HStack {
                        Image(systemName: bluetoothService.isScanning ? "stop.circle" : "magnifyingglass")
                        Text(bluetoothService.isScanning ? "Scanning..." : "Scan")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(bluetoothService.isScanning ? Color.red : Color.blue)
                    .clipShape(Capsule())
                }
            }
            .padding()
            
            // Device List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(bluetoothService.availableDevices) { device in
                        DeviceCardView(
                            device: device,
                            isConnected: bluetoothService.connectedDevice?.id == device.id,
                            connectionState: bluetoothService.connectionState
                        ) {
                            connectToDevice(device)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Refresh Button
            Button(action: {
                let span = SessionManager.shared.createUserInteractionSpan(
                    action: "refresh_devices",
                    screen: "DevicesView"
                )
                bluetoothService.refreshDevices()
                span?.finish()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Devices")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .alert(isPresented: $showingConnectionError) {
            Alert(
                title: Text("Connection Error"),
                message: Text(bluetoothService.lastError?.localizedDescription ?? "Unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(bluetoothService.$lastError) { error in
            if error != nil {
                showingConnectionError = true
            }
        }
    }
}

// MARK: - Device Card View

struct DeviceCardView: View {
    let device: BluetoothDevice
    let isConnected: Bool
    let connectionState: BluetoothService.ConnectionState
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            // Device Icon
            Image(systemName: device.deviceType.icon)
                .font(.title2)
                .foregroundColor(isConnected ? .green : .blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // Device Name
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Device Info
                HStack {
                    Text(device.deviceType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Signal Strength
                    HStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            Rectangle()
                                .frame(width: 3, height: CGFloat(4 + index * 2))
                                .foregroundColor(signalColor(for: index))
                        }
                    }
                    
                    Text("\(device.signalStrength)%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Battery Level (if applicable)
                if let batteryLevel = device.batteryLevel {
                    HStack {
                        Image(systemName: "battery.75")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(batteryLevel)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Connect Button
            Button(action: onConnect) {
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if connectionState == .connecting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Connect")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .disabled(isConnected || connectionState == .connecting)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func signalColor(for index: Int) -> Color {
        let strengthLevel = device.signalStrength / 25 // Convert to 0-4 scale
        return index < strengthLevel ? .green : .gray.opacity(0.3)
    }
}

// MARK: - Mini Player View

struct MiniPlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let onExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // Track Info
                VStack(alignment: .leading, spacing: 2) {
                    if let track = audioPlayer.currentTrack {
                        Text(track.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Play/Pause Button
                Button(action: {
                    let span = SessionManager.shared.createUserInteractionSpan(
                        action: "mini_player_control",
                        screen: "MiniPlayer"
                    )
                    
                    if audioPlayer.playbackState == .playing {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                    
                    span?.setTag(value: audioPlayer.playbackState == .playing ? "pause" : "play", key: "action")
                    span?.finish()
                }) {
                    Image(systemName: audioPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                let span = SessionManager.shared.createUserInteractionSpan(
                    action: "expand_mini_player",
                    screen: "MiniPlayer"
                )
                onExpand()
                span?.finish()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 