import App
import SwiftUI

struct VintageAmberTimerFace: View {
    let view: TimerView
    let onTapTime: () -> Void
    let onPrimary: () -> Void

    private let amber = Color(red: 0xFF / 255.0, green: 0xB3 / 255.0, blue: 0x47 / 255.0)
    private let warningAmber = Color(red: 0xFF / 255.0, green: 0x99 / 255.0, blue: 0x33 / 255.0)
    private let rustBorder = Color(red: 0x6B / 255.0, green: 0x53 / 255.0, blue: 0x35 / 255.0)
    private let trackColor = Color(red: 0x2D / 255.0, green: 0x1F / 255.0, blue: 0x0F / 255.0)
    private let tickMinor = Color(red: 0x8B / 255.0, green: 0x6F / 255.0, blue: 0x47 / 255.0)
    private let tickMajor = Color(red: 0xAA / 255.0, green: 0x88 / 255.0, blue: 0x55 / 255.0)
    private let digitOff = Color(red: 0xFF / 255.0, green: 0x8C / 255.0, blue: 0x00 / 255.0).opacity(0.09)

    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let digitWidth = (minSide - 64) / 5 - 24
            let digitHeight = digitWidth * 80 / 48
            let buttonSize = minSide / 3
            let remaining = TimerFaceMath.remaining(view)
            let progress = TimerFaceMath.progress(view)

            ZStack {
                // Rustic noise background
                RusticNoise().allowsHitTesting(false)

                // Radial amber glow
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0xFF / 255.0, green: 0x8C / 255.0, blue: 0x00 / 255.0).opacity(0.03),
                        .clear
                    ]),
                    center: .center, startRadius: 0, endRadius: minSide * 0.8
                )
                .allowsHitTesting(false)

                // Outer rusty border
                VintageArcShape(progress: 1.0)
                    .stroke(rustBorder, style: StrokeStyle(lineWidth: 44, lineCap: .round))
                    .frame(width: minSide, height: minSide)

                // Background track
                VintageArcShape(progress: 1.0)
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 36, lineCap: .round))
                    .frame(width: minSide, height: minSide)

                // Tick marks
                VintageTicks(minor: tickMinor, major: tickMajor)
                    .frame(width: minSide, height: minSide)

                // Progress arc + glow
                if progress > 0 {
                    VintageArcShape(progress: progress)
                        .stroke(warningAmber, style: StrokeStyle(lineWidth: 32 * 0.8, lineCap: .round))
                        .frame(width: minSide, height: minSide)
                        .shadow(color: Color(red: 0xFF / 255.0, green: 0x8C / 255.0, blue: 0x00 / 255.0).opacity(0.5), radius: 12)
                        .shadow(color: amber.opacity(0.3), radius: 4)
                }

                // Scratches
                VintageScratches().frame(width: minSide, height: minSide)

                Button(action: onTapTime) {
                    SevenSegmentDisplay(
                        minutes: Int(remaining) / 60,
                        seconds: Int(remaining) % 60,
                        onColor: amber,
                        offColor: digitOff,
                        digitWidth: digitWidth,
                        digitHeight: digitHeight,
                        segmentThickness: 10
                    )
                }
                .buttonStyle(.plain)

                if view.status == .completed {
                    BellAnimation(size: digitHeight * 1.2, color: amber)
                        .offset(y: -(digitHeight * 0.5 + digitHeight * 1.25) + 8)
                        .allowsHitTesting(false)
                }

                // CRT scan lines overlay
                CRTScanLines().allowsHitTesting(false)

                Button(action: onPrimary) {
                    primaryIconStroke(view, lineWidth: (minSide / 4) / 10)
                        .foregroundStyle(warningAmber)
                        .frame(width: minSide / 4, height: minSide / 4)
                        .shadow(color: Color(red: 0xFF / 255.0, green: 0x8C / 255.0, blue: 0x00 / 255.0), radius: 12)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
                .offset(x: minSide / 3 - 24, y: minSide / 3 - 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct VintageArcShape: Shape {
    let progress: Double
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let minSide = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = minSide * 0.4
        let startAngle = -CGFloat.pi * 1.5
        let sweep = CGFloat.pi * 1.5 * CGFloat(progress)
        if progress <= 0 { return path }
        path.addArc(center: center, radius: radius,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(startAngle + sweep),
                    clockwise: false)
        return path
    }
}

private struct VintageTicks: View {
    let minor: Color
    let major: Color

    var body: some View {
        Canvas { context, size in
            let minSide = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = minSide * 0.4
            let startAngle = -CGFloat.pi * 1.5
            let sweep = CGFloat.pi * 1.5
            let tickCount = 27
            let strokeWidth: CGFloat = 32

            for i in 0...tickCount {
                let t = CGFloat(i) / CGFloat(tickCount)
                let angle = startAngle + sweep * t
                let isMajor = i % 3 == 0
                let innerR = radius + strokeWidth / 2 + 8
                let outerR = innerR + (isMajor ? 10 : 5)
                let p1 = CGPoint(x: center.x + innerR * cos(angle), y: center.y + innerR * sin(angle))
                let p2 = CGPoint(x: center.x + outerR * cos(angle), y: center.y + outerR * sin(angle))
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                context.stroke(
                    path,
                    with: .color(isMajor ? major : minor),
                    style: StrokeStyle(lineWidth: isMajor ? 2 : 1.5, lineCap: .round)
                )
            }
        }
    }
}

private struct VintageScratches: View {
    var body: some View {
        Canvas { context, size in
            let minSide = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = minSide * 0.4
            let startAngle = -CGFloat.pi * 1.5
            let sweep = CGFloat.pi * 1.5
            let strokeWidth: CGFloat = 32
            var rng = SeededRandom(seed: 42)

            for _ in 0..<8 {
                let angle = startAngle + sweep * CGFloat(rng.next())
                let length = strokeWidth * (0.5 + CGFloat(rng.next()) * 0.5)
                let start = CGPoint(
                    x: center.x + (radius - strokeWidth / 2) * cos(angle),
                    y: center.y + (radius - strokeWidth / 2) * sin(angle)
                )
                let end = CGPoint(
                    x: center.x + (radius - strokeWidth / 2 + length) * cos(angle),
                    y: center.y + (radius - strokeWidth / 2 + length) * sin(angle)
                )
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(Color.black.opacity(0.12)),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
}

private struct RusticNoise: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: 12345)
            for _ in 0..<3000 {
                let x = CGFloat(rng.next()) * size.width
                let y = CGFloat(rng.next()) * size.height
                let opacity = CGFloat(rng.next()) * 0.4 + 0.1
                let useAmber = rng.next() > 0.5
                let color = useAmber
                    ? Color(red: 139 / 255.0, green: 111 / 255.0, blue: 71 / 255.0).opacity(opacity * 0.3)
                    : Color(red: 107 / 255.0, green: 83 / 255.0, blue: 53 / 255.0).opacity(opacity * 0.2)
                let dot = Path(ellipseIn: CGRect(x: x - 0.8, y: y - 0.8, width: 1.6, height: 1.6))
                context.fill(dot, with: .color(color))
            }
        }
    }
}

private struct CRTScanLines: View {
    var body: some View {
        Canvas { context, size in
            let color = Color.black.opacity(0.04)
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(color))
                y += 3
            }
        }
    }
}

private struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1_000_000) / 1_000_000.0
    }
}

private let vintageBg = Color(red: 0x2D / 255.0, green: 0x1F / 255.0, blue: 0x0F / 255.0)

#Preview("Vintage idle") {
    ZStack {
        vintageBg.ignoresSafeArea()
        VintageAmberTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 0, status: .idle),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Vintage running") {
    ZStack {
        vintageBg.ignoresSafeArea()
        VintageAmberTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 6 * 60 + 23, status: .running),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Vintage completed") {
    ZStack {
        vintageBg.ignoresSafeArea()
        VintageAmberTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 15 * 60, status: .completed),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}
