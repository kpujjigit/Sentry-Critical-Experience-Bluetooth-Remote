import UIKit
import SwiftUI
import Sentry

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var userSessionTransaction: Span?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        // Start a long-running user session transaction
        userSessionTransaction = SentrySDK.startTransaction(
            name: "User Session",
            operation: "app.session"
        )
        
        // Add session context
        userSessionTransaction?.setTag(value: "ios_simulator", key: "platform")
        userSessionTransaction?.setTag(value: Bundle.main.bundleIdentifier ?? "unknown", key: "app_id")
        userSessionTransaction?.setTag(value: session.persistentIdentifier, key: "session_id")
        userSessionTransaction?.setTag(value: UIDevice.current.systemVersion, key: "ios_version")
        userSessionTransaction?.setTag(value: UIDevice.current.model, key: "device_model")
        userSessionTransaction?.setTag(value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown", key: "app_version")

        window = UIWindow(windowScene: windowScene)
        
        // Ensure main actor services are created on the main thread
        Task { @MainActor in
            do {
                // Create service instances on main actor
                let bluetoothService = BluetoothService()
                let audioPlayerService = AudioPlayerService(bluetoothService: bluetoothService)
                
                // Create the main content view with environment objects
                let contentView = ContentView()
                    .environmentObject(bluetoothService)
                    .environmentObject(audioPlayerService)
                
                let hostingController = UIHostingController(rootView: contentView)
                window?.rootViewController = hostingController
                window?.makeKeyAndVisible()
                
                // Add breadcrumb for session start
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .info,
                    category: "session.lifecycle"
                ))
                
                print("✅ App UI setup completed successfully")
                
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
        
        // Note: userSessionTransaction stays active - DO NOT finish it here
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
        
        // End the user session transaction when scene disconnects
        userSessionTransaction?.setTag(value: "disconnected", key: "session_end_reason")
        userSessionTransaction?.finish()
        userSessionTransaction = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
        
        // If we don't have an active session transaction, start one
        if userSessionTransaction == nil {
            userSessionTransaction = SentrySDK.startTransaction(
                name: "User Session",
                operation: "app.session"
            )
            userSessionTransaction?.setTag(value: "reactivated", key: "session_start_reason")
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
        
        // Optionally end session on background (or keep it running)
        // For this demo, we'll keep the session running unless disconnected
    }
} 