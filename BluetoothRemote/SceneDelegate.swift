import UIKit
import SwiftUI
import Sentry

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        window = UIWindow(windowScene: windowScene)
        
        // Create service instances on main actor
        Task { @MainActor in
            do {
                // Start user session for trace continuity
                SessionManager.shared.startUserSession()
                
                let bluetoothService = BluetoothService()
                let audioPlayerService = AudioPlayerService(bluetoothService: bluetoothService)
                
                let contentView = ContentView()
                    .environmentObject(bluetoothService)
                    .environmentObject(audioPlayerService)
                    .environmentObject(SessionManager.shared)
                
                let hostingController = UIHostingController(rootView: contentView)
                window?.rootViewController = hostingController
                window?.makeKeyAndVisible()
                
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .info,
                    category: "app.lifecycle"
                ))
                
                print("✅ App UI setup completed with session: \(SessionManager.shared.sessionId ?? "unknown")")
                
            } catch {
                print("❌ Error setting up app UI: \(error)")
                SentrySDK.capture(error: error)
                
                // Fallback: Show a simple error view
                let errorView = Text("App failed to initialize. Please restart.")
                    .foregroundColor(.red)
                    .padding()
                let errorController = UIHostingController(rootView: errorView)
                window?.rootViewController = errorController
                window?.makeKeyAndVisible()
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // End user session when app disconnects
        Task { @MainActor in
            SessionManager.shared.finishUserSession()
        }
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }

    func sceneWillResignActive(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Update session context for background state
        Task { @MainActor in
            SessionManager.shared.updateSessionContext(
                connectedDevice: nil,
                currentTrack: nil,
                playbackState: "background"
            )
        }
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }
} 