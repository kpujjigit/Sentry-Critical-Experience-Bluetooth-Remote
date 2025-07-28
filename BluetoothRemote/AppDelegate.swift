import UIKit
import Sentry

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Read Sentry DSN from environment variable or use placeholder
        let sentryDSN = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? "https://2cd5f78faaf215a707d856b152feace9@o4504052292517888.ingest.us.sentry.io/4509725305929728"
        let sentryOrg = ProcessInfo.processInfo.environment["SENTRY_ORG"] ?? "kporg"
        let sentryProject = ProcessInfo.processInfo.environment["SENTRY_PROJECT"] ?? "kp-bt-remote-cx"
        let sentryEnvironment = ProcessInfo.processInfo.environment["SENTRY_ENVIRONMENT"] ?? "demo"
        let sentryRelease = ProcessInfo.processInfo.environment["SENTRY_RELEASE"] ?? "bluetooth-remote@0.0.1"

        SentrySDK.start { options in
            options.dsn = sentryDSN
            options.debug = true
            options.environment = sentryEnvironment
            // Note: release property not available in this Sentry version
            
            // Performance Tracing Configuration
            options.tracesSampleRate = 1.0 // 100% sampling for demo
            options.enableAutoPerformanceTracing = true
            options.enableUIViewControllerTracing = true
            options.enableNetworkTracking = true
            options.enableFileIOTracing = true
            options.enableCoreDataTracing = true
            options.enableUserInteractionTracing = true
            options.enableTimeToFullDisplayTracing = true
            options.enablePerformanceV2 = true
            options.enablePreWarmedAppStartTracing = true
            
            // Mobile Vitals & Performance Insights Configuration
            options.enableAppLaunchProfiling = true // App start performance tracking
            options.enableFramesTracking = true // Slow/frozen frame detection
            options.enableAppHangTracking = true // ANR/hang detection
            options.appHangTimeoutInterval = 2.0 // Detect hangs > 2 seconds
            options.enableAutoSessionTracking = true // Session health monitoring
            
            // Network Performance Monitoring
            options.enableNetworkBreadcrumbs = true // Network request breadcrumbs
            options.enableCaptureFailedRequests = true // Failed network requests
            
            // Mobile Session Replay Configuration
            options.sessionReplay.sessionSampleRate = 1.0 // 100% for demo
            options.sessionReplay.onErrorSampleRate = 1.0 // Capture on all errors
            options.sessionReplay.maskAllText = true // Privacy: mask all text by default
            options.sessionReplay.maskAllImages = true // Privacy: mask all images
            
            // UI Profiling Configuration (iOS 8.49.0+)
            options.configureProfiling = { profilingOptions in
                profilingOptions.sessionSampleRate = 1.0 // 100% for demo
                profilingOptions.lifecycle = .trace // Trace-based profiling for complete coverage
            }
            
            // Error Monitoring with Mobile Context
            options.attachStacktrace = true
            options.maxBreadcrumbs = 150
            options.sendDefaultPii = true
            
            // iOS-specific Performance Features
            options.enableMetricKit = true // iOS MetricKit integration for system metrics
            options.enableWatchdogTerminationTracking = true // Track app terminations
            options.enableOutOfMemoryTracking = true // Track OOM crashes
            
            // Session Health Configuration
            options.sessionTrackingIntervalMillis = 30000 // 30-second session tracking interval
            
            // Note: Custom tags will be set per event
        }
        
        // Set demo user context
        SentrySDK.setUser(User(userId: "demo-user-\(UUID().uuidString.prefix(8))"))
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "lifecycle"
        ))
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "lifecycle"
        ))
    }
} 
