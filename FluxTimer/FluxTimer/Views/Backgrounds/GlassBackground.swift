import SwiftUI
import AppKit

struct GlassBackground: View {
    var accentColor: Color = .purple
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            // macOS vibrancy blur
            VisualEffectBackground()

            // Inner border to catch light
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)

            // Subtle accent glow at edges
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 2)
                .blur(radius: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
