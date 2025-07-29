import UIKit
import Sentry

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Read Sentry DSN from environment variable or use placeholder
        let sentryDSN = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? "https://2cd5f78faaf215a707d856b152feace9@o4504052292517888.ingest.us.sentry.io/4509725305929728"
        let sentryEnvironment = ProcessInfo.processInfo.environment["SENTRY_ENVIRONMENT"] ?? "demo"
        let sentryRelease = ProcessInfo.processInfo.environment["SENTRY_RELEASE"] ?? "bluetooth-remote@0.0.1"

        SentrySDK.start { options in
            options.dsn = sentryDSN
            options.debug = true
            options.environment = sentryEnvironment
            options.releaseName = sentryRelease
            
            // Performance & Tracing Configuration
            options.tracesSampleRate = 1.0 // 100% sampling for demo
            options.enableAutoPerformanceTracing = true // Enables automatic instrumentation
            
            // Automatic features (enabled by default when enableAutoPerformanceTracing = true):
            // - UIViewController Tracing (doesn't work for SwiftUI - handled manually)
            // - App Start Tracing (automatic app launch measurement)
            // - Slow and Frozen Frames (automatic Mobile Vitals)
            // - Network Tracking (automatic HTTP request spans)
            // - File I/O Tracing (automatic file operation spans)
            // - Core Data Tracing (automatic database spans)
            // - User Interaction Tracing (doesn't work for SwiftUI - handled manually)
            
            // Additional Performance Options
            options.enableTimeToFullDisplayTracing = true
            options.enablePerformanceV2 = true // Enhanced frame rendering measurement
            options.enablePreWarmedAppStartTracing = true
            
            // Session & Health Monitoring
            options.enableAutoSessionTracking = true // Automatic session management
            options.enableAppHangTracking = true // ANR/hang detection
            options.appHangTimeoutInterval = 2.0
            
            // App termination tracking (iOS 14+)
            if #available(iOS 14.0, *) {
                options.enableWatchdogTerminationTracking = true
            }
            
            // Error & Context Configuration
            options.attachStacktrace = true
            options.maxBreadcrumbs = 150
            options.sendDefaultPii = true
            options.enableCaptureFailedRequests = true
            
            // Mobile Session Replay
            options.sessionReplay.sessionSampleRate = 1.0 // 100% for demo
            options.sessionReplay.onErrorSampleRate = 1.0
            
            // Profiling Configuration (for detailed performance analysis)
            options.configureProfiling = { profilingOptions in
                profilingOptions.sessionSampleRate = 1.0 // 100% for demo
                profilingOptions.lifecycle = .trace
            }
        }
        
        // Set demo user context
        SentrySDK.setUser(User(userId: "demo-user-\(UUID().uuidString.prefix(8))"))
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "app.lifecycle"
        ))
    }
} 
