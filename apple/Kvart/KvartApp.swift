import App
import SwiftUI
import UserNotifications

@main
struct KvartApp: App {
    @StateObject private var core = Core.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            TimerScreen(core: core)
                .onOpenURL { url in
                    guard url.scheme == "kvart" else { return }
                    let text = url.host ?? url.path.trimmingCharacters(in: .init(charactersIn: "/"))
                    core.send(TimerEvent.setFromText(text))
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                core.send(BackgroundEvent.resume(nowMs()))
            case .background, .inactive:
                core.send(BackgroundEvent.enter(nowMs()))
            @unknown default:
                break
            }
        }
    }
}
