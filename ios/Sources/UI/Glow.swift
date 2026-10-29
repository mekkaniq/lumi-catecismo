import SwiftUI

/// Fundo em shader Metal (gradiente suave com luz dourada) e poeira dourada flutuando.
/// O shader é suave, então renderiza em um terço da resolução para poupar bateria.
struct GlowBackground: View {
    let theme: Theme
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var t0 = Date()

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion || !animated)) { tl in
                let t = reduceMotion || !animated ? 12.0 : tl.date.timeIntervalSince(t0) + 7.0
                GeometryReader { geo in
                    let f: CGFloat = 3
                    let small = CGSize(width: max(2, geo.size.width / f), height: max(2, geo.size.height / f))
                    Rectangle()
                        .fill(theme.glow[0])
                        .frame(width: small.width, height: small.height)
                        .colorEffect(ShaderLibrary.lumiGlow(
                            .float2(small),
                            .float(t),
                            .color(theme.glow[0]),
                            .color(theme.glow[1]),
                            .color(theme.glow[2])))
                        .scaleEffect(f, anchor: .topLeading)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                        .clipped()
                }
            }
            GoldDust(paused: reduceMotion || !animated)
        }
        .accessibilityHidden(true)
    }
}

/// Pontinhos de luz dourada subindo devagar, como brasas da sarça.
struct GoldDust: View {
    var paused = false

    private func fract(_ x: Double) -> Double { x - floor(x) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused)) { tl in
            Canvas { ctx, size in
                let t = paused ? 30.0 : tl.date.timeIntervalSinceReferenceDate
                for i in 0..<24 {
                    let s = Double(i) * 12.9898
                    let x = fract(sin(s) * 43758.5453)
                    let speed = 0.010 + 0.022 * fract(sin(s * 1.7) * 913.7)
                    let y = 1 - fract(fract(sin(s * 2.3) * 977.3) + t * speed)
                    let r = 1.0 + 2.2 * fract(sin(s * 3.1) * 311.9)
                    let tw = 0.5 + 0.5 * sin(t * 1.3 + s)
                    let cx = x * size.width + sin(t * 0.3 + s) * 9
                    let cy = y * size.height
                    let edge = min(1, min(y, 1 - y) * 6)
                    let a = (0.12 + 0.5 * tw) * edge
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - r * 3, y: cy - r * 3, width: r * 6, height: r * 6)),
                             with: .color(Pal.brightGold.opacity(a * 0.18)))
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                             with: .color(Pal.brightGold.opacity(a)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
