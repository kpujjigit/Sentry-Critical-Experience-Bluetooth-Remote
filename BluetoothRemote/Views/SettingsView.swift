import SwiftUI
import Sentry

struct SettingsView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @EnvironmentObject var bluetoothService: BluetoothService
    @State private var showingCrashAlert = false
    @State private var showingErrorAlert = false
    @State private var showingSentryDemo = false
    @State private var isLoggingVerbose = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Sentry Demo Features
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sentry Demo Features")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Button("Trigger Demo Error") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "trigger_demo_error",
                                screen: "SettingsView"
                            )
                            SentrySDK.addBreadcrumb(Breadcrumb(
                                level: .warning,
                                category: "sentry.demo"
                            ))
                            let error = NSError(domain: "DemoApp", code: 100, userInfo: [NSLocalizedDescriptionKey: "This is a simulated error from the Bluetooth Remote app."])
                            SentrySDK.capture(error: error) { scope in
                                scope.setTag(value: "user_action", key: "error_source")
                                scope.setContext(value: [
                                    "connected_device": bluetoothService.connectedDevice?.name ?? "None",
                                    "current_track": audioPlayer.currentTrack?.title ?? "None",
                                    "playback_state": audioPlayer.playbackState.rawValue,
                                    "volume": audioPlayer.audioSettings.volume,
                                    "playlist_size": audioPlayer.currentPlaylist.count
                                ], key: "app_state")
                            }
                            showingErrorAlert = true
                            span?.finish()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Simulate Native Crash") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "simulate_crash",
                                screen: "SettingsView"
                            )
                            SentrySDK.addBreadcrumb(Breadcrumb(
                                level: .fatal,
                                category: "sentry.demo"
                            ))
                            showingCrashAlert = true
                            span?.finish()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .alert(isPresented: $showingCrashAlert) {
                            Alert(
                                title: Text("Simulate Crash"),
                                message: Text("This will cause the app to crash immediately. The crash report will be sent to Sentry on next launch."),
                                primaryButton: .destructive(Text("Confirm Crash")) {
                                    SentrySDK.crash()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button("Advanced Sentry Demo") {
                            showingSentryDemo = true
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .sheet(isPresented: $showingSentryDemo) {
                            SentryDemoSheet(audioPlayer: audioPlayer, bluetoothService: bluetoothService)
                        }
                        
                        Toggle("Verbose Logging", isOn: $isLoggingVerbose)
                            .onChange(of: isLoggingVerbose) { enabled in
                                let span = SessionManager.shared.createUserInteractionSpan(
                                    action: "toggle_logging",
                                    screen: "SettingsView"
                                )
                                SentrySDK.addBreadcrumb(Breadcrumb(
                                    level: .info,
                                    category: "sentry.settings"
                                ))
                                span?.setTag(value: "\(enabled)", key: "verbose_enabled")
                                span?.finish()
                            }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // App Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("App Information")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                        }
                        
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("1")
                        }
                        
                        HStack {
                            Text("Sentry SDK Version")
                            Spacer()
                            Text("8.53.2")
                        }
                        
                        HStack {
                            Text("Target Device")
                            Spacer()
                            Text("iOS 14+")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .onAppear {
                // Create screen load span as part of the active session
                let screenLoadSpan = SessionManager.shared.createScreenLoadSpan(screenName: "SettingsView")
                
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
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Demo Error Triggered"),
                message: Text("A demonstration error has been sent to Sentry. Check your Sentry dashboard to see how error monitoring works."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Advanced Sentry Demo Sheet

struct SentryDemoSheet: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    @ObservedObject var bluetoothService: BluetoothService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var customTag = ""
    @State private var customMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Performance Monitoring
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Monitoring")
                            .font(.headline)
                        
                        Button("Generate Random Breadcrumbs") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "generate_breadcrumbs",
                                screen: "SettingsView"
                            )
                            
                            for _ in 0..<3 {
                                SentrySDK.addBreadcrumb(Breadcrumb(
                                    level: .info,
                                    category: "user.action"
                                ))
                            }
                            
                            span?.setTag(value: "3", key: "breadcrumbs_generated")
                            span?.finish()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                                            Button("Start Performance Transaction") {
                            let span = SessionManager.shared.createUserInteractionSpan(
                                action: "start_performance_test",
                                screen: "SettingsView"
                            )
                            // Simulate some async work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                span?.setTag(value: "completed", key: "operation_status")
                                span?.finish()
                            }
                        }
                    }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Error Monitoring
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Error Monitoring")
                            .font(.headline)
                        
                        TextField("Custom Error Message", text: $customMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Send Custom Error") {
                            guard !customMessage.isEmpty else { return }
                            
                            let error = NSError(domain: "CustomDemo", code: 200, userInfo: [
                                NSLocalizedDescriptionKey: customMessage
                            ])
                            
                            SentrySDK.capture(error: error) { scope in
                                scope.setTag(value: "user_generated", key: "error_type")
                                scope.setContext(value: [
                                    "connected_device": bluetoothService.connectedDevice?.name ?? "None",
                                    "current_track": audioPlayer.currentTrack?.title ?? "None",
                                    "playback_state": audioPlayer.playbackState.rawValue,
                                    "volume": audioPlayer.audioSettings.volume
                                ], key: "app_state")
                            }
                            
                            customMessage = ""
                        }
                        .disabled(customMessage.isEmpty)
                        .padding()
                        .background(customMessage.isEmpty ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Sentry Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let bluetoothService = BluetoothService()
        let audioPlayer = AudioPlayerService(bluetoothService: bluetoothService)
        
        return SettingsView(audioPlayer: audioPlayer)
            .environmentObject(bluetoothService)
    }
} 