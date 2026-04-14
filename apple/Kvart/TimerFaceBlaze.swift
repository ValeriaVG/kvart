import App
import SwiftUI

struct BlazeTimerFace: View {
    let view: TimerView
    let onTapTime: () -> Void
    let onPrimary: () -> Void

    private let gradientColors: [Color] = [
        Color(red: 0xE5 / 255.0, green: 0x1A / 255.0, blue: 0x55 / 255.0),
        Color(red: 0xF8 / 255.0, green: 0x52 / 255.0, blue: 0x62 / 255.0),
        Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0),
        Color(red: 0xFF / 255.0, green: 0xD5 / 255.0, blue: 0x29 / 255.0)
    ]
    private let digitOn = Color(red: 0xFF / 255.0, green: 0xE4 / 255.0, blue: 0xB5 / 255.0)
    private let digitOff = Color(red: 0xFF / 255.0, green: 0xE4 / 255.0, blue: 0xB5 / 255.0).opacity(0.07)

    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let digitWidth = (minSide - 64) / 5 - 24
            let digitHeight = digitWidth * 80 / 48
            let buttonSize = minSide / 3
            let remaining = TimerFaceMath.remaining(view)
            let progress = TimerFaceMath.progress(view)

            ZStack {
                // Warm radial glow background
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0xE5 / 255.0, green: 0x1A / 255.0, blue: 0x55 / 255.0).opacity(0.09), location: 0),
                        .init(color: Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0).opacity(0.03), location: 0.5),
                        .init(color: .clear, location: 1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: minSide * 0.6
                )
                .allowsHitTesting(false)

                // Background track (white 5%)
                BlazeTrack()
                    .stroke(Color.white.opacity(0.05),
                            style: StrokeStyle(lineWidth: 32, lineCap: .round))
                    .frame(width: minSide, height: minSide)

                // Gradient progress arc + outer glow
                if progress > 0 {
                    let arcGradient = AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .radians(.pi / 2),
                        endAngle: .radians(.pi / 2 + .pi * 1.5)
                    )
                    BlazeProgressArc(progress: progress)
                        .stroke(arcGradient, style: StrokeStyle(lineWidth: 32, lineCap: .round))
                        .frame(width: minSide, height: minSide)
                        .shadow(color: Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0).opacity(0.55), radius: 18)
                        .shadow(color: Color(red: 0xF8 / 255.0, green: 0x52 / 255.0, blue: 0x62 / 255.0).opacity(0.35), radius: 6)

                    // Pulsing outer glow when paused
                    if view.status == .paused {
                        BlazeProgressArc(progress: progress)
                            .stroke(arcGradient, style: StrokeStyle(lineWidth: 48, lineCap: .butt))
                            .frame(width: minSide, height: minSide)
                            .blur(radius: 20)
                            .modifier(BlazePulseModifier())
                            .allowsHitTesting(false)
                    }

                    // Ember particles when running
                    if view.status == .running {
                        BlazeEmbers(progress: progress)
                            .frame(width: minSide, height: minSide)
                            .allowsHitTesting(false)
                    }
                }

                Button(action: onTapTime) {
                    SevenSegmentDisplay(
                        minutes: Int(remaining) / 60,
                        seconds: Int(remaining) % 60,
                        onColor: digitOn,
                        offColor: digitOff,
                        digitWidth: digitWidth,
                        digitHeight: digitHeight
                    )
                }
                .buttonStyle(.plain)

                if view.status == .completed {
                    BellAnimation(size: digitHeight * 1.2, color: digitOn)
                        .offset(y: -(digitHeight * 0.5 + digitHeight * 1.25) + 8)
                        .allowsHitTesting(false)
                }

                Button(action: onPrimary) {
                    primaryIconStroke(view, lineWidth: (minSide / 4) / 10)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors.reversed(),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: minSide / 4, height: minSide / 4)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
                .offset(x: minSide / 3 - 24, y: minSide / 3 - 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct BlazeTrack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let minSide = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = minSide * 0.4
        path.addArc(center: center, radius: radius,
                    startAngle: .radians(.pi / 2),
                    endAngle: .radians(.pi / 2 + .pi * 1.5),
                    clockwise: false)
        return path
    }
}

private struct BlazeProgressArc: Shape {
    let progress: Double
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let minSide = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = minSide * 0.4
        let startAngle = CGFloat.pi / 2
        let sweep = CGFloat.pi * 1.5 * CGFloat(progress)
        path.addArc(center: center, radius: radius,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(startAngle + sweep),
                    clockwise: false)
        return path
    }
}

private struct BlazePulseModifier: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? 0.7 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    on = true
                }
            }
    }
}

private final class BlazeEmber {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var speed: CGFloat
    var drift: CGFloat
    var life: CGFloat
    var size: CGFloat
    var arcPosition: CGFloat
    var color: Color

    init(rng: inout SystemRandomNumberGenerator) {
        speed = 0.4 + CGFloat.random(in: 0...1, using: &rng) * 0.8
        drift = (CGFloat.random(in: 0...1, using: &rng) - 0.5) * 0.6
        life = 0.7 + CGFloat.random(in: 0...1, using: &rng) * 0.3
        size = 1.5 + CGFloat.random(in: 0...1, using: &rng) * 2.5
        arcPosition = CGFloat.random(in: 0...1, using: &rng)
        let palette: [Color] = [
            Color(red: 0xFF / 255.0, green: 0xD5 / 255.0, blue: 0x29 / 255.0),
            Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0),
            Color(red: 0xF8 / 255.0, green: 0x52 / 255.0, blue: 0x62 / 255.0),
            Color(red: 0xFF / 255.0, green: 0xAA / 255.0, blue: 0x33 / 255.0)
        ]
        color = palette[Int.random(in: 0..<palette.count, using: &rng)]
    }
}

private struct BlazeEmbers: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            Canvas { ctx, size in
                let state = EmberStore.shared
                state.tick(at: context.date)

                let minSide = min(size.width, size.height)
                let radius = minSide * 0.4
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let startAngle = CGFloat.pi / 2
                let sweep = CGFloat.pi * 1.5 * CGFloat(progress)

                for ember in state.embers {
                    let angle = startAngle + sweep * ember.arcPosition
                    let baseX = center.x + radius * cos(angle)
                    let baseY = center.y + radius * sin(angle)
                    let point = CGPoint(x: baseX + ember.x, y: baseY + ember.y)
                    let rect = CGRect(
                        x: point.x - ember.size,
                        y: point.y - ember.size,
                        width: ember.size * 2,
                        height: ember.size * 2
                    )
                    let opacity = max(0, min(1, ember.life)) * 0.8
                    var innerCtx = ctx
                    innerCtx.addFilter(.blur(radius: 3))
                    innerCtx.fill(Path(ellipseIn: rect), with: .color(ember.color.opacity(opacity)))
                }
            }
        }
    }
}

private final class EmberStore {
    static let shared = EmberStore()
    var embers: [BlazeEmber] = []
    private var rng = SystemRandomNumberGenerator()
    private var lastTick: Date?

    func tick(at date: Date) {
        let dt: CGFloat
        if let last = lastTick {
            dt = CGFloat(min(0.05, date.timeIntervalSince(last)))
        } else {
            dt = 1.0 / 60.0
        }
        lastTick = date

        // ~60 ticks/sec → spawn probability tuned to Flutter's 0.3 per frame
        let spawnChance = 0.3 * (dt * 60.0)
        if embers.count < 14 && CGFloat.random(in: 0...1, using: &rng) < spawnChance {
            embers.append(BlazeEmber(rng: &rng))
        }

        let step = dt * 60.0
        for ember in embers {
            ember.life -= 0.012 * step
            ember.y -= ember.speed * step
            ember.x += ember.drift * step
        }
        embers.removeAll { $0.life <= 0 }
    }
}

private let blazeBg = Color(red: 0x0C / 255.0, green: 0x0B / 255.0, blue: 0x0B / 255.0)

#Preview("Blaze idle") {
    ZStack {
        blazeBg.ignoresSafeArea()
        BlazeTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 0, status: .idle),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Blaze running") {
    ZStack {
        blazeBg.ignoresSafeArea()
        BlazeTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 6 * 60 + 23, status: .running),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}

#Preview("Blaze completed") {
    ZStack {
        blazeBg.ignoresSafeArea()
        BlazeTimerFace(
            view: TimerView(secondsTotal: 15 * 60, secondsElapsed: 15 * 60, status: .completed),
            onTapTime: {}, onPrimary: {}
        )
        .padding(24)
    }
}
