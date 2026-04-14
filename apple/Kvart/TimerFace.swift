import App
import SwiftUI

struct TimerFace: View {
    let view: TimerView
    let theme: ThemeId
    let onTapTime: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        switch theme {
        case .modern:
            ModernTimerFace(view: view, onTapTime: onTapTime, onPrimary: onPrimary)
        case .blaze:
            BlazeTimerFace(view: view, onTapTime: onTapTime, onPrimary: onPrimary)
        case .vintageAmber:
            VintageAmberTimerFace(view: view, onTapTime: onTapTime, onPrimary: onPrimary)
        }
    }
}

// MARK: - Shared helpers

enum TimerFaceMath {
    static func remaining(_ view: TimerView) -> UInt32 {
        view.secondsElapsed >= view.secondsTotal ? 0 : view.secondsTotal - view.secondsElapsed
    }

    static func progress(_ view: TimerView) -> Double {
        guard view.secondsTotal > 0 else { return 0 }
        return Double(remaining(view)) / Double(view.secondsTotal)
    }
}

// MARK: - Lucide icon shapes (shared)

struct LucideRepeat: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let tx = rect.minX + (rect.width - 24 * s) / 2
        let ty = rect.minY + (rect.height - 24 * s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: tx + x * s, y: ty + y * s)
        }
        var path = Path()
        path.move(to: p(17, 2))
        path.addLine(to: p(21, 6))
        path.addLine(to: p(17, 10))
        path.move(to: p(3, 11))
        path.addLine(to: p(3, 9))
        path.addQuadCurve(to: p(7, 5), control: p(3, 6.79))
        path.addLine(to: p(21, 5))
        path.move(to: p(7, 22))
        path.addLine(to: p(3, 18))
        path.addLine(to: p(7, 14))
        path.move(to: p(21, 13))
        path.addLine(to: p(21, 15))
        path.addQuadCurve(to: p(17, 19), control: p(21, 17.21))
        path.addLine(to: p(3, 19))
        return path
    }
}

struct LucidePlay: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let tx = rect.minX + (rect.width - 24 * s) / 2
        let ty = rect.minY + (rect.height - 24 * s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: tx + x * s, y: ty + y * s)
        }
        var path = Path()
        path.move(to: p(5, 19))
        path.addLine(to: p(5, 5))
        path.addQuadCurve(to: p(8.008, 3.272), control: p(5, 3))
        path.addLine(to: p(20.005, 10.27))
        path.addQuadCurve(to: p(20.008, 13.728), control: p(21.736, 12))
        path.addLine(to: p(8.008, 20.728))
        path.addQuadCurve(to: p(5, 19), control: p(5, 21))
        path.closeSubpath()
        return path
    }
}

struct LucidePause: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let tx = rect.minX + (rect.width - 24 * s) / 2
        let ty = rect.minY + (rect.height - 24 * s) / 2
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: tx + 5 * s, y: ty + 3 * s, width: 5 * s, height: 18 * s),
            cornerSize: CGSize(width: 1 * s, height: 1 * s)
        )
        path.addRoundedRect(
            in: CGRect(x: tx + 14 * s, y: ty + 3 * s, width: 5 * s, height: 18 * s),
            cornerSize: CGSize(width: 1 * s, height: 1 * s)
        )
        return path
    }
}

@ViewBuilder
func primaryIconStroke(_ view: TimerView, lineWidth: CGFloat) -> some View {
    let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    switch view.status {
    case .running: LucidePause().stroke(style: stroke)
    case .completed: LucideRepeat().stroke(style: stroke)
    default: LucidePlay().stroke(style: stroke)
    }
}

@ViewBuilder
func primaryIconFill(_ view: TimerView) -> some View {
    switch view.status {
    case .running: LucidePause().fill(style: FillStyle(eoFill: false))
    case .completed: LucideRepeat().stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    default: LucidePlay().fill(style: FillStyle(eoFill: false))
    }
}

// MARK: - Modern theme

struct ModernTimerFace: View {
    let view: TimerView
    let onTapTime: () -> Void
    let onPrimary: () -> Void

    private let accent = Color(red: 0xC5 / 255.0, green: 0xF9 / 255.0, blue: 0x74 / 255.0)
    private let track = Color(red: 0x0A / 255.0, green: 0x1A / 255.0, blue: 0x30 / 255.0)

    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let digitWidth = (minSide - 64) / 5 - 24
            let digitHeight = digitWidth * 80 / 48
            let buttonSize = minSide / 3

            ZStack {
                ModernArc(progress: TimerFaceMath.progress(view), accent: accent, track: track)
                    .frame(width: minSide, height: minSide)

                Button(action: onTapTime) {
                    SevenSegmentDisplay(
                        minutes: Int(TimerFaceMath.remaining(view)) / 60,
                        seconds: Int(TimerFaceMath.remaining(view)) % 60,
                        digitWidth: digitWidth,
                        digitHeight: digitHeight
                    )
                }
                .buttonStyle(.plain)

                if view.status == .completed {
                    BellAnimation(size: digitHeight * 1.2, color: .white)
                        .offset(y: -(digitHeight * 0.5 + digitHeight * 1.25) + 8)
                        .allowsHitTesting(false)
                }

                Button(action: onPrimary) {
                    ZStack {
                        Circle().fill(track)
                        primaryIconStroke(view, lineWidth: (minSide / 4) / 12)
                            .frame(width: minSide / 4, height: minSide / 4)
                            .foregroundStyle(accent.opacity(0.75))
                    }
                    .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
                .offset(x: minSide / 3 - 24, y: minSide / 3 - 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct ModernArc: View {
    let progress: Double
    let accent: Color
    let track: Color

    var body: some View {
        Canvas { context, size in
            let minSide = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = minSide * 0.4
            let startAngle = -CGFloat.pi * 1.5
            let sweepAngle = CGFloat.pi * 1.5

            let background = Path { path in
                path.addArc(center: center, radius: radius,
                            startAngle: .radians(startAngle),
                            endAngle: .radians(startAngle + sweepAngle),
                            clockwise: false)
            }
            context.stroke(background, with: .color(track),
                           style: StrokeStyle(lineWidth: 40, lineCap: .round))

            if progress > 0 {
                let foreground = Path { path in
                    path.addArc(center: center, radius: radius,
                                startAngle: .radians(startAngle),
                                endAngle: .radians(startAngle + sweepAngle * progress),
                                clockwise: false)
                }
                context.stroke(foreground, with: .color(accent),
                               style: StrokeStyle(lineWidth: 32, lineCap: .round))
            }
        }
    }
}

private let modernBg = Color(red: 0x02 / 255.0, green: 0x0C / 255.0, blue: 0x1D / 255.0)

#Preview("Modern idle") {
    ZStack {
        modernBg.ignoresSafeArea()
        ModernTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 0, status: .idle),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Modern running") {
    ZStack {
        modernBg.ignoresSafeArea()
        ModernTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 6 * 60 + 23, status: .running),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Modern completed") {
    ZStack {
        modernBg.ignoresSafeArea()
        ModernTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 15 * 60, status: .completed),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}
