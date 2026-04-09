import SwiftUI

struct GradientBackground: View {
    let palette: GradientPalette
    let progress: Double

    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0

    var body: some View {
        let colors = palette.colors(at: progress)

        ZStack {
            // Base gradient layer — fills the entire area
            LinearGradient(
                colors: [colors[0], colors[1]],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Second layer — slow clockwise rotation
            LinearGradient(
                colors: [colors[1].opacity(0.6), colors[2].opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .rotationEffect(.degrees(rotation1))
            .scaleEffect(1.5) // oversized so rotation doesn't show corners
            .blendMode(.screen)

            // Third layer — slow counter-clockwise
            RadialGradient(
                colors: [colors[2].opacity(0.3), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
            .rotationEffect(.degrees(rotation2))
            .scaleEffect(1.5)
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
                rotation2 = -360
            }
        }
    }
}
