import ActivityKit
import App
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenTimerView(state: context.state, themeId: ThemePalette.fromString(context.attributes.themeId))
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let theme = ThemePalette.fromString(context.attributes.themeId)
            let accent = ThemePalette.accent(theme)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(accent)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownText(for: context.state)
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TrailBar(state: context.state, themeId: theme)
                        .frame(height: 8)
                        .clipShape(Capsule())
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(accent)
            } compactTrailing: {
                countdownText(for: context.state)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(accent)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.status == .running ? "timer" : "pause.circle")
                    .foregroundStyle(accent)
            }
        }
    }
}

private struct LockScreenTimerView: View {
    let state: TimerActivityAttributes.ContentState
    let themeId: ThemeId

    var body: some View {
        ZStack {
            TrailBar(state: state, themeId: themeId)

            SevenSegDigits(state: state, themeId: themeId)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(height: 96)
    }
}

private struct TrailBar: View {
    let state: TimerActivityAttributes.ContentState
    let themeId: ThemeId

    var body: some View {
        GeometryReader { geo in
            let gradient = ThemePalette.gradient(themeId)
            switch state.status {
            case .running:
                TimelineView(.periodic(from: Date(), by: 0.5)) { ctx in
                    let fraction = runningFraction(at: ctx.date)
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(gradient)
                            .frame(width: max(0, geo.size.width * (1 - fraction)))
                        Spacer(minLength: 0)
                    }
                }
            case .paused:
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(gradient)
                        .opacity(0.6)
                        .frame(width: max(0, geo.size.width * (1 - state.fractionAtPause)))
                    Spacer(minLength: 0)
                }
            case .completed:
                EmptyView()
            }
        }
    }

    private func runningFraction(at date: Date) -> Double {
        let now = UInt64(date.timeIntervalSince1970 * 1000)
        let total = max(state.endMs, state.startMs + 1) - state.startMs
        let elapsed = now > state.startMs ? now - state.startMs : 0
        let clamped = min(elapsed, total)
        return Double(clamped) / Double(total)
    }
}

private struct SevenSegDigits: View {
    let state: TimerActivityAttributes.ContentState
    let themeId: ThemeId

    var body: some View {
        let accent = ThemePalette.accent(themeId)
        GeometryReader { geo in
            let digitWidth = min(geo.size.width / 7, geo.size.height * 0.55)
            let digitHeight = digitWidth * 1.6
            let thickness = max(3, digitWidth * 0.16)

            Group {
                switch state.status {
                case .running:
                    TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                        let remaining = remainingSeconds(at: ctx.date)
                        display(accent: accent,
                                width: digitWidth,
                                height: digitHeight,
                                thickness: thickness,
                                seconds: remaining,
                                disabled: false)
                    }
                case .paused:
                    let remaining = staticRemaining()
                    display(accent: accent,
                            width: digitWidth,
                            height: digitHeight,
                            thickness: thickness,
                            seconds: remaining,
                            disabled: false)
                        .opacity(0.7)
                case .completed:
                    display(accent: accent,
                            width: digitWidth,
                            height: digitHeight,
                            thickness: thickness,
                            seconds: 0,
                            disabled: false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func display(accent: Color,
                         width: CGFloat,
                         height: CGFloat,
                         thickness: CGFloat,
                         seconds: UInt32,
                         disabled: Bool) -> some View {
        SevenSegmentDisplay(
            minutes: Int(seconds / 60),
            seconds: Int(seconds % 60),
            onColor: .white,
            offColor: accent.opacity(0.15),
            digitWidth: width,
            digitHeight: height,
            segmentThickness: thickness,
            disabled: disabled
        )
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    private func remainingSeconds(at date: Date) -> UInt32 {
        let now = UInt64(date.timeIntervalSince1970 * 1000)
        guard state.endMs > now else { return 0 }
        return UInt32((state.endMs - now + 999) / 1000)
    }

    private func staticRemaining() -> UInt32 {
        state.secondsTotal > state.secondsElapsed
            ? state.secondsTotal - state.secondsElapsed
            : 0
    }
}

@ViewBuilder
private func countdownText(for state: TimerActivityAttributes.ContentState) -> some View {
    switch state.status {
    case .running:
        let endDate = Date(timeIntervalSince1970: TimeInterval(state.endMs) / 1000)
        Text(timerInterval: Date()...endDate, countsDown: true)
    case .paused:
        let remaining = state.secondsTotal > state.secondsElapsed
            ? state.secondsTotal - state.secondsElapsed
            : 0
        Text(formatSeconds(remaining))
    case .completed:
        Text("00:00")
    }
}

private func formatSeconds(_ seconds: UInt32) -> String {
    let minutes = seconds / 60
    let secs = seconds % 60
    return String(format: "%02d:%02d", minutes, secs)
}
