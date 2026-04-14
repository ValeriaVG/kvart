import SwiftUI

struct LucideBellRing: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let tx = rect.minX + (rect.width - 24 * s) / 2
        let ty = rect.minY + (rect.height - 24 * s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: tx + x * s, y: ty + y * s)
        }
        var path = Path()

        // Clapper: M10.268 21 a 2 2 0 0 0 3.464 0
        path.move(to: p(10.268, 21))
        path.addQuadCurve(to: p(13.732, 21), control: p(12, 23))

        // Right ring: M22 8 c 0 -2.3 -0.8 -4.3 -2 -6
        path.move(to: p(22, 8))
        path.addCurve(to: p(20, 2), control1: p(22, 5.7), control2: p(21.2, 3.7))

        // Bell body
        path.move(to: p(3.262, 15.326))
        // a 1 1 0 0 0 .738 1.674 → to (4, 17)
        path.addQuadCurve(to: p(4, 17), control: p(3.262, 17))
        // h 16
        path.addLine(to: p(20, 17))
        // a 1 1 0 0 0 .74 -1.673 → to (20.74, 15.327)
        path.addQuadCurve(to: p(20.74, 15.327), control: p(20.74, 17))
        // C 19.41 13.956 18 12.499 18 8
        path.addCurve(to: p(18, 8), control1: p(19.41, 13.956), control2: p(18, 12.499))
        // A 6 6 0 0 0 6 8 → half-arc across top, radius 6
        path.addArc(
            center: p(12, 8),
            radius: 6 * s,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: true
        )
        // c 0 4.499 -1.411 5.956 -2.738 7.326 → back to (3.262, 15.326)
        path.addCurve(
            to: p(3.262, 15.326),
            control1: p(6, 12.499),
            control2: p(4.589, 13.956)
        )

        // Left ring: M4 2 C 2.8 3.7 2 5.7 2 8
        path.move(to: p(4, 2))
        path.addCurve(to: p(2, 8), control1: p(2.8, 3.7), control2: p(2, 5.7))

        return path
    }
}

struct BellAnimation: View {
    var size: CGFloat = 64
    var color: Color = .white

    @State private var phase: Double = 0

    private let period: Double = 0.5
    private let maxAngle: Angle = .degrees(30)

    var body: some View {
        LucideBellRing()
            .stroke(style: StrokeStyle(
                lineWidth: size / 24 * 2,
                lineCap: .round,
                lineJoin: .round
            ))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .rotationEffect(maxAngle * triangleWave(phase))
            .task {
                let start = Date()
                let stopAfter: TimeInterval = 5
                while true {
                    let elapsed = Date().timeIntervalSince(start)
                    if elapsed >= stopAfter { break }
                    let t = elapsed.truncatingRemainder(dividingBy: period) / period
                    withAnimation(.easeInOut(duration: 1.0 / 60.0)) {
                        phase = t
                    }
                    try? await Task.sleep(nanoseconds: 16_000_000)
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    phase = 0
                }
            }
    }

    // Maps [0,1] → triangle wave matching Flutter TweenSequence:
    // 0..0.25: 0 → 0.3, 0.25..0.75: 0.3 → -0.3, 0.75..1: -0.3 → 0
    private func triangleWave(_ t: Double) -> Double {
        let eased: (Double) -> Double = { x in
            x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
        }
        if t < 0.25 {
            return 0.3 * eased(t / 0.25)
        } else if t < 0.75 {
            let q = (t - 0.25) / 0.5
            return 0.3 + (-0.6) * eased(q)
        } else {
            let q = (t - 0.75) / 0.25
            return -0.3 + 0.3 * eased(q)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        BellAnimation(size: 160, color: .white)
    }
    .ignoresSafeArea()
}
