import SwiftUI

/// Fundo em shader Metal: gradiente vivo, luz de glória no alto e brasa embaixo.
/// Renderiza em meia resolução para poupar bateria.
struct GlowBackground: View {
    let theme: Theme
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var t0 = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion || !animated)) { tl in
            let t = reduceMotion || !animated ? 12.0 : tl.date.timeIntervalSince(t0) + 7.0
            GeometryReader { geo in
                let half = CGSize(width: max(2, geo.size.width / 2), height: max(2, geo.size.height / 2))
                Rectangle()
                    .fill(theme.glow[0])
                    .frame(width: half.width, height: half.height)
                    .colorEffect(ShaderLibrary.lumiGlow(
                        .float2(half),
                        .float(t),
                        .color(theme.glow[0]),
                        .color(theme.glow[1]),
                        .color(theme.glow[2])))
                    .scaleEffect(2, anchor: .topLeading)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                    .clipped()
            }
        }
        .accessibilityHidden(true)
    }
}
