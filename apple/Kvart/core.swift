import ActivityKit
import App
import AVFoundation
import CoreHaptics
import Foundation
import Shared
import UIKit
import UserNotifications

@MainActor
class Core: ObservableObject {
    static let shared = Core()

    @Published var view: ViewModel

    private var core: CoreFfi
    private var ticker: Timer?
    private var alarmPlayer: AVAudioPlayer?
    private var hapticEngine: CHHapticEngine?
    private var activity: Activity<TimerActivityAttributes>?
    private var intentObservers: [NSObjectProtocol] = []

    private static let persistenceKey = "kvart.persisted.v1"
    private var lastPersistedBytes: [UInt8] = []

    init() {
        self.core = CoreFfi()
        // swiftlint:disable:next force_try
        self.view = try! .bincodeDeserialize(input: [UInt8](core.view()))
        hydrateFromDisk()
        registerIntentObservers()
        adoptExistingActivity()
    }

    private func adoptExistingActivity() {
        let existing = Activity<TimerActivityAttributes>.activities
        guard let first = existing.first else { return }
        self.activity = first
        for extra in existing.dropFirst() {
            Task { await extra.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private func hydrateFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else { return }
        do {
            let state = try PersistedState.bincodeDeserialize(input: [UInt8](data))
            update(.hydrate(state))
        } catch {
            // Saved blob is from an older schema; drop it.
            UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
        }
    }

    private func persistIfChanged() {
        // swiftlint:disable:next force_try
        let bytes = try! view.persisted.bincodeSerialize()
        guard bytes != lastPersistedBytes else { return }
        lastPersistedBytes = bytes
        UserDefaults.standard.set(Data(bytes), forKey: Self.persistenceKey)
    }

    deinit {
        ticker?.invalidate()
        for observer in intentObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func registerIntentObservers() {
        let center = NotificationCenter.default
        let toggle = center.addObserver(forName: .kvartTimerToggle, object: nil, queue: .main) { _ in
            Task { @MainActor in Core.shared.handleToggleIntent() }
        }
        let reset = center.addObserver(forName: .kvartTimerReset, object: nil, queue: .main) { _ in
            Task { @MainActor in Core.shared.send(.reset) }
        }
        let terminate = center.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in Core.shared.endActivityOnTerminate() }
        }
        intentObservers = [toggle, reset, terminate]
    }

    private func endActivityOnTerminate() {
        for activity in Activity<TimerActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        self.activity = nil
    }

    private func handleToggleIntent() {
        switch view.timer.status {
        case .running: send(.pause(nowMs()))
        case .paused, .idle: send(.start(nowMs()))
        case .completed: break
        }
    }

    func update(_ event: Event) {
        // swiftlint:disable:next force_try
        let effects = [UInt8](core.update(Data(try! event.bincodeSerialize())))
        // swiftlint:disable:next force_try
        let requests: [Request] = try! .bincodeDeserialize(input: effects)
        for request in requests {
            processEffect(request)
        }
        syncTicker()
        syncActivity()
        syncLocale()
        persistIfChanged()
    }

    private func syncLocale() {
        LocaleBundle.override = view.settings.language.code ?? NSLocale.current.language.languageCode?.identifier
    }

    func send(_ timer: TimerEvent) { update(.timer(timer)) }
    func send(_ themes: ThemesEvent) { update(.themes(themes)) }
    func send(_ settings: SettingsEvent) { update(.settings(settings)) }
    func send(_ background: BackgroundEvent) { update(.background(background)) }

    private func processEffect(_ request: Request) {
        switch request.effect {
        case .render:
            // swiftlint:disable:next force_try
            self.view = try! .bincodeDeserialize(input: [UInt8](self.core.view()))
        case .alarm(let op):
            handleAlarm(op)
        }
    }

    private func handleAlarm(_ op: AlarmOperation) {
        switch op {
        case .fire(let soundAsset, let vibrate):
            fireAlarm(soundAsset: soundAsset, vibrate: vibrate)
        case .schedule(let atMs, let soundAsset, let vibrate):
            scheduleAlarm(atMs: atMs, soundAsset: soundAsset, vibrate: vibrate)
        case .cancel:
            cancelScheduledAlarm()
        }
    }

    private func fireAlarm(soundAsset: String, vibrate: Bool) {
        if !soundAsset.isEmpty,
           let url = Bundle.main.url(forResource: soundAsset, withExtension: "mp3") {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                alarmPlayer = player
            } catch {
                // Best-effort playback.
            }
        }
        if vibrate {
            playCountdownTimerAlertHaptic()
        }
    }

    private func playCountdownTimerAlertHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        do {
            if hapticEngine == nil {
                let engine = try CHHapticEngine()
                engine.isAutoShutdownEnabled = true
                engine.resetHandler = { [weak self] in
                    try? self?.hapticEngine?.start()
                }
                engine.stoppedHandler = { [weak self] _ in
                    self?.hapticEngine = nil
                }
                hapticEngine = engine
            }
            try hapticEngine?.start()

            // Mirrors the Flutter `vibration` package's `countdownTimerAlert` preset:
            // pattern    [0, 100, 100, 200, 100, 300, 100, 400, 100, 500] ms
            // intensities[0, 100,   0, 150,   0, 200,   0, 255,   0, 255] / 255
            let segments: [(wait: Double, duration: Double, intensity: Float)] = [
                (0.000, 0.100, 100.0 / 255.0),
                (0.100, 0.200, 150.0 / 255.0),
                (0.100, 0.300, 200.0 / 255.0),
                (0.100, 0.400, 1.0),
                (0.100, 0.500, 1.0)
            ]
            var events: [CHHapticEvent] = []
            var t = 0.0
            for segment in segments {
                t += segment.wait
                events.append(
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: segment.intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                        ],
                        relativeTime: t,
                        duration: segment.duration
                    )
                )
                t += segment.duration
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func scheduleAlarm(atMs: UInt64, soundAsset: String, vibrate: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.scheduledAlarmId])

        let nowMsValue = nowMs()
        let secondsUntil = Double(atMs > nowMsValue ? atMs - nowMsValue : 0) / 1000.0
        let interval = max(secondsUntil, 1.0)

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your timer has finished!"
        if !soundAsset.isEmpty {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundAsset + ".mp3"))
        } else {
            content.sound = .default
        }
        if vibrate {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.scheduledAlarmId,
            content: content,
            trigger: trigger
        )
        center.add(request) { _ in }
    }

    private func cancelScheduledAlarm() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.scheduledAlarmId])
    }

    private static let scheduledAlarmId = "kvart.timer.completion"

    private func syncActivity() {
        let timer = view.timer
        let attrs = TimerActivityAttributes(themeId: themeIdString(view.themes.selected))

        let contentStatus: TimerActivityAttributes.ContentState.Status
        switch timer.status {
        case .running: contentStatus = .running
        case .paused: contentStatus = .paused
        case .completed: contentStatus = .completed
        case .idle:
            if let activity = activity {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
                self.activity = nil
            }
            return
        }

        let remaining = timer.secondsTotal > timer.secondsElapsed
            ? timer.secondsTotal - timer.secondsElapsed
            : 0
        let now = nowMs()
        let endMs = now + UInt64(remaining) * 1000
        let startMs = timer.secondsTotal > 0
            ? endMs - UInt64(timer.secondsTotal) * 1000
            : now
        let fraction = timer.secondsTotal > 0
            ? Double(timer.secondsElapsed) / Double(timer.secondsTotal)
            : 0

        let state = TimerActivityAttributes.ContentState(
            status: contentStatus,
            startMs: startMs,
            endMs: endMs,
            secondsTotal: timer.secondsTotal,
            secondsElapsed: timer.secondsElapsed,
            fractionAtPause: fraction
        )
        let staleDate: Date? = contentStatus == .running
            ? Date(timeIntervalSince1970: TimeInterval(endMs) / 1000).addingTimeInterval(5)
            : nil
        let content = ActivityContent(state: state, staleDate: staleDate)

        if let activity = activity {
            Task { await activity.update(content) }
            if contentStatus == .completed {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await activity.end(content, dismissalPolicy: .default)
                }
                self.activity = nil
            }
        } else if contentStatus == .running {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            for stray in Activity<TimerActivityAttributes>.activities {
                Task { await stray.end(nil, dismissalPolicy: .immediate) }
            }
            do {
                activity = try Activity.request(attributes: attrs, content: content, pushType: nil)
            } catch {
                // Live Activities unavailable; ignore.
            }
        }
    }

    private func themeIdString(_ id: ThemeId) -> String {
        switch id {
        case .modern: return "modern"
        case .blaze: return "blaze"
        case .vintageAmber: return "vintageAmber"
        }
    }

    private func syncTicker() {
        switch view.timer.status {
        case .running:
            guard ticker == nil else { return }
            ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.send(.tick(nowMs())) }
            }
        default:
            ticker?.invalidate()
            ticker = nil
        }
    }
}

func nowMs() -> UInt64 {
    UInt64(Date().timeIntervalSince1970 * 1000)
}
