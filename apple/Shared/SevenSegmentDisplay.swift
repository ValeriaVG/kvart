import SwiftUI

struct SevenSegmentDigit: View {
    let digit: Int?
    let onColor: Color
    let offColor: Color
    let width: CGFloat
    let height: CGFloat
    let segmentThickness: CGFloat

    var body: some View {
        Canvas { context, size in
            let segments = Self.segments(for: digit)
            let t = segmentThickness
            let topY = t / 2
            let middleY = size.height / 2
            let bottomY = size.height - t / 2
            let leftX = t / 2
            let rightX = size.width - t / 2
            let centerX = size.width / 2
            let segHeight = size.height / 2 - t / 2
            let segWidth = size.width - t

            func draw(_ path: Path, lit: Bool) {
                context.fill(path, with: .color(lit ? onColor : offColor))
            }

            draw(Self.horizontalPath(center: CGPoint(x: centerX, y: topY), length: segWidth, thickness: t), lit: segments[0])
            draw(Self.verticalPath(center: CGPoint(x: rightX, y: middleY - segHeight / 2), length: segHeight, thickness: t), lit: segments[1])
            draw(Self.verticalPath(center: CGPoint(x: rightX, y: middleY + segHeight / 2), length: segHeight, thickness: t), lit: segments[2])
            draw(Self.horizontalPath(center: CGPoint(x: centerX, y: bottomY), length: segWidth, thickness: t), lit: segments[3])
            draw(Self.verticalPath(center: CGPoint(x: leftX, y: middleY + segHeight / 2), length: segHeight, thickness: t), lit: segments[4])
            draw(Self.verticalPath(center: CGPoint(x: leftX, y: middleY - segHeight / 2), length: segHeight, thickness: t), lit: segments[5])
            draw(Self.horizontalPath(center: CGPoint(x: centerX, y: middleY), length: segWidth, thickness: t), lit: segments[6])
        }
        .frame(width: width, height: height)
        .padding(segmentThickness / 2)
    }

    private static func segments(for digit: Int?) -> [Bool] {
        switch digit {
        case 0: return [true, true, true, true, true, true, false]
        case 1: return [false, true, true, false, false, false, false]
        case 2: return [true, true, false, true, true, false, true]
        case 3: return [true, true, true, true, false, false, true]
        case 4: return [false, true, true, false, false, true, true]
        case 5: return [true, false, true, true, false, true, true]
        case 6: return [true, false, true, true, true, true, true]
        case 7: return [true, true, true, false, false, false, false]
        case 8: return [true, true, true, true, true, true, true]
        case 9: return [true, true, true, true, false, true, true]
        default: return [false, false, false, false, false, false, false]
        }
    }

    private static func horizontalPath(center: CGPoint, length: CGFloat, thickness: CGFloat) -> Path {
        var path = Path()
        let cx = center.x
        let cy = center.y
        let w = length
        let h = thickness
        path.move(to: CGPoint(x: cx - w / 2, y: cy))
        path.addLine(to: CGPoint(x: cx - w / 2 + h / 2, y: cy - h / 2))
        path.addLine(to: CGPoint(x: cx + w / 2 - h / 2, y: cy - h / 2))
        path.addLine(to: CGPoint(x: cx + w / 2, y: cy))
        path.addLine(to: CGPoint(x: cx + w / 2 - h / 2, y: cy + h / 2))
        path.addLine(to: CGPoint(x: cx - w / 2 + h / 2, y: cy + h / 2))
        path.closeSubpath()
        return path
    }

    private static func verticalPath(center: CGPoint, length: CGFloat, thickness: CGFloat) -> Path {
        var path = Path()
        let cx = center.x
        let cy = center.y
        let w = thickness
        let h = length
        path.move(to: CGPoint(x: cx, y: cy - h / 2))
        path.addLine(to: CGPoint(x: cx + w / 2, y: cy - h / 2 + w / 2))
        path.addLine(to: CGPoint(x: cx + w / 2, y: cy + h / 2 - w / 2))
        path.addLine(to: CGPoint(x: cx, y: cy + h / 2))
        path.addLine(to: CGPoint(x: cx - w / 2, y: cy + h / 2 - w / 2))
        path.addLine(to: CGPoint(x: cx - w / 2, y: cy - h / 2 + w / 2))
        path.closeSubpath()
        return path
    }
}

struct DigitSeparator: View {
    let color: Color
    let thickness: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let r = thickness / 2
            let top = CGRect(x: centerX - r, y: size.height * 0.25 - r, width: thickness, height: thickness)
            let bottom = CGRect(x: centerX - r, y: size.height * 0.75 - r, width: thickness, height: thickness)
            context.fill(Path(ellipseIn: top), with: .color(color))
            context.fill(Path(ellipseIn: bottom), with: .color(color))
        }
        .frame(width: thickness * 2, height: height)
    }
}

struct SevenSegmentDisplay: View {
    let minutes: Int
    let seconds: Int
    var onColor: Color = .white
    var offColor: Color = Color.white.opacity(0.05)
    var digitWidth: CGFloat = 48
    var digitHeight: CGFloat = 80
    var segmentThickness: CGFloat = 8
    var disabled: Bool = false

    var body: some View {
        let minTens = (minutes / 10) % 10
        let minUnits = minutes % 10
        let secTens = (seconds / 10) % 10
        let secUnits = seconds % 10
        let spacing = segmentThickness / 2

        HStack(spacing: spacing) {
            digit(disabled ? nil : minTens)
            digit(disabled ? nil : minUnits)
            DigitSeparator(
                color: disabled ? offColor : onColor,
                thickness: segmentThickness,
                height: digitHeight
            )
            digit(disabled ? nil : secTens)
            digit(disabled ? nil : secUnits)
        }
    }

    private func digit(_ value: Int?) -> some View {
        SevenSegmentDigit(
            digit: value,
            onColor: onColor,
            offColor: offColor,
            width: digitWidth,
            height: digitHeight,
            segmentThickness: segmentThickness
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SevenSegmentDisplay(minutes: 12, seconds: 34)
    }
}
