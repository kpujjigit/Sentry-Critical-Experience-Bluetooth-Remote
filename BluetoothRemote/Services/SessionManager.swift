import Foundation
import Sentry

@MainActor
class SessionManager: ObservableObject {
    // Current session transaction that ties all user interactions together
    private var sessionTransaction: Span?
    private var sessionStartTime: Date?
    
    // Singleton pattern for app-wide access
    static let shared = SessionManager()
    
    private init() {}
    
    // MARK: - Session Lifecycle Management
    
    func startUserSession() {
        // Start a new session transaction that will contain all user interactions
        sessionTransaction = SentrySDK.startTransaction(
            name: "User Session",
            operation: "user.session"
        )
        sessionStartTime = Date()
        
        sessionTransaction?.setTag(value: "active", key: "session_status")
        sessionTransaction?.setTag(value: UUID().uuidString, key: "session_id")
        
        // Add user context as tags (since setContext may not be available on Span)
        sessionTransaction?.setTag(value: "mobile_app", key: "session_type")
        sessionTransaction?.setTag(value: "foreground", key: "app_state")
        sessionTransaction?.setTag(value: "swiftui", key: "ui_framework")
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
        
        print("🎯 Session started: \(sessionTransaction?.description ?? "unknown")")
    }
    
    func finishUserSession() {
        guard let transaction = sessionTransaction else { return }
        
        if let startTime = sessionStartTime {
            let sessionDuration = Date().timeIntervalSince(startTime)
            transaction.setData(value: Int(sessionDuration), key: "session_duration_seconds")
        }
        
        transaction.setTag(value: "completed", key: "session_status")
        transaction.finish()
        
        SentrySDK.addBreadcrumb(Breadcrumb(
            level: .info,
            category: "session.lifecycle"
        ))
        
        print("🎯 Session finished: \(transaction.description)")
        sessionTransaction = nil
        sessionStartTime = nil
    }
    
    // MARK: - Span Creation Helpers
    
    // Create a child span of the current session transaction
    func createSpan(operation: String, description: String) -> Span? {
        guard let transaction = sessionTransaction else {
            print("⚠️ No active session - creating fallback transaction for: \(description)")
            // Fallback: create a standalone transaction if no session exists
            let fallbackTransaction = SentrySDK.startTransaction(name: description, operation: operation)
            fallbackTransaction.setTag(value: "fallback", key: "span_type")
            return fallbackTransaction
        }
        
        let span = transaction.startChild(operation: operation, description: description)
        span.setTag(value: "session_child", key: "span_type")
        return span
    }
    
    // Create a user interaction span (for UI actions)
    func createUserInteractionSpan(action: String, screen: String) -> Span? {
        let span = createSpan(
            operation: "ui.action.user",
            description: "User \(action) on \(screen)"
        )
        span?.setTag(value: action, key: "user_action")
        span?.setTag(value: screen, key: "screen_name")
        span?.setTag(value: "true", key: "is_user_action")
        return span
    }
    
    // Create a screen load span
    func createScreenLoadSpan(screenName: String) -> Span? {
        let span = createSpan(
            operation: "ui.screen.load",
            description: "Load \(screenName) Screen"
        )
        span?.setTag(value: screenName, key: "screen_name")
        span?.setTag(value: "swiftui", key: "ui_framework")
        return span
    }
    
    // Create a bluetooth operation span
    func createBluetoothSpan(operation: String, description: String, deviceName: String? = nil) -> Span? {
        let span = createSpan(
            operation: "bt.\(operation)",
            description: description
        )
        if let device = deviceName {
            span?.setTag(value: device, key: "device_name")
        }
        span?.setTag(value: "bluetooth", key: "operation_type")
        return span
    }
    
    // Update session context with current app state
    func updateSessionContext(connectedDevice: String?, currentTrack: String?, playbackState: String?) {
        // Update tags with current app state (since setContext may not be available on Span)
        sessionTransaction?.setTag(value: connectedDevice ?? "none", key: "connected_device")
        sessionTransaction?.setTag(value: currentTrack ?? "none", key: "current_track")
        sessionTransaction?.setTag(value: playbackState ?? "stopped", key: "playback_state")
        sessionTransaction?.setData(value: Int(Date().timeIntervalSince1970), key: "last_updated")
    }
    
    // MARK: - Session Health
    
    var isSessionActive: Bool {
        return sessionTransaction != nil
    }
    
    var sessionId: String? {
        return sessionTransaction?.tags["session_id"]
    }
} 