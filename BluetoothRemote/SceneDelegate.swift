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
                let bluetoothService = BluetoothService()
                let audioPlayerService = AudioPlayerService(bluetoothService: bluetoothService)
                
                let contentView = ContentView()
                    .environmentObject(bluetoothService)
                    .environmentObject(audioPlayerService)
                
                let hostingController = UIHostingController(rootView: contentView)
                window?.rootViewController = hostingController
                window?.makeKeyAndVisible()
                
                SentrySDK.addBreadcrumb(Breadcrumb(
                    level: .info,
                    category: "app.lifecycle"
                ))
                
                print("✅ App UI setup completed")
                
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
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }
} 