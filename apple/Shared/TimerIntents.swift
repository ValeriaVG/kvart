import AppIntents
import Foundation

extension Notification.Name {
    static let kvartTimerToggle = Notification.Name("kvart.timer.toggle")
    static let kvartTimerReset = Notification.Name("kvart.timer.reset")
}

struct TimerToggleIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or Resume Timer"
    static var description = IntentDescription("Pauses or resumes the running timer.")

    init() {}

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .kvartTimerToggle, object: nil)
        return .result()
    }
}

struct TimerResetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description = IntentDescription("Resets the timer.")

    init() {}

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .kvartTimerReset, object: nil)
        return .result()
    }
}
