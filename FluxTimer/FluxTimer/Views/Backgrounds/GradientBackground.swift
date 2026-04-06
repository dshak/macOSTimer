import SwiftUI

struct GradientBackground: View {
    let palette: GradientPalette
    let progress: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GradientCanvas(
                palette: palette,
                progress: progress,
                time: timeline.date.timeIntervalSinceReferenceDate
            )
        }
    }
}

private struct GradientCanvas: View {
    let palette: GradientPalette
    let progress: Double
    let time: TimeInterval

    var body: some View {
        Canvas { ctx, size in
            let angle1 = time.truncatingRemainder(dividingBy: 30) / 30 * .pi * 2
            let angle2 = -time.truncatingRemainder(dividingBy: 45) / 45 * .pi * 2

            let colors = palette.colors(at: progress)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height) * 0.8
            let rect = Path(CGRect(origin: .zero, size: size))

            // First radial gradient — rotates clockwise
            let offset1 = CGPoint(
                x: center.x + cos(angle1) * size.width * 0.15,
                y: center.y + sin(angle1) * size.height * 0.15
            )
            ctx.fill(rect, with: .radialGradient(
                Gradient(colors: [colors[0], colors[1].opacity(0.6)]),
                center: offset1, startRadius: 0, endRadius: radius
            ))

            // Second radial gradient — rotates counter-clockwise, blended
            let offset2 = CGPoint(
                x: center.x + cos(angle2) * size.width * 0.2,
                y: center.y + sin(angle2) * size.height * 0.2
            )
            ctx.blendMode = .screen
            ctx.fill(rect, with: .radialGradient(
                Gradient(colors: [colors[1].opacity(0.7), colors[2].opacity(0.5)]),
                center: offset2, startRadius: 0, endRadius: radius * 0.9
            ))

            // Third subtle overlay for depth
            ctx.blendMode = .normal
            ctx.fill(rect, with: .radialGradient(
                Gradient(colors: [colors[2].opacity(0.3), .clear]),
                center: CGPoint(x: size.width * 0.8, y: size.height * 0.2),
                startRadius: 0, endRadius: radius * 0.6
            ))
        }
        .drawingGroup()
    }
}
