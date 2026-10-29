import SwiftUI

// MARK: - estilos de botão e cartão

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PillStyle: ButtonStyle {
    enum Kind { case solid, plain, gold }
    var kind: Kind = .plain
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(fg)
            .background(bg, in: Capsule())
            .overlay(Capsule().stroke(kind == .plain ? Pal.line : .clear, lineWidth: 1))
            .shadow(color: kind == .plain ? .clear : shadowColor.opacity(0.35), radius: 8, y: 5)
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var fg: Color { kind == .gold ? Color(hex: 0x1a1405) : kind == .solid ? .white : Pal.fg }
    private var shadowColor: Color { kind == .gold ? Pal.gold : theme.primary }
    private var bg: AnyShapeStyle {
        switch kind {
        case .solid: return AnyShapeStyle(LinearGradient(colors: [theme.primary.opacity(0.85), theme.primary], startPoint: .top, endPoint: .bottom))
        case .gold: return AnyShapeStyle(LinearGradient(colors: [Pal.gold.opacity(0.85), Pal.gold], startPoint: .top, endPoint: .bottom))
        case .plain: return AnyShapeStyle(Pal.surface)
        }
    }
}

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(Pal.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Pal.line.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.07), radius: 14, y: 8)
    }
}

extension View {
    func card(radius: CGFloat = 20) -> some View { modifier(CardModifier(radius: radius)) }

    /// Barra de navegação na cor do livro, com botão de tamanho da letra.
    func lumiBar(_ theme: Theme, solid: Bool, title: String = "") -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.deep, for: .navigationBar)
            .toolbarBackground(Visibility.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { FontSizeButton() } }
    }
}

struct FontSizeButton: View {
    @EnvironmentObject private var store: Store
    var body: some View {
        Button { store.cycleFont() } label: {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("A").font(.footnote.bold())
                Text("A").font(.title3.bold())
            }
        }
        .accessibilityLabel("Tamanho da letra. Toque para mudar")
    }
}

// MARK: - peças visuais

struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 6, y: 15))
        p.addCurve(to: CGPoint(x: 1.6, y: 9.8), control1: CGPoint(x: 2.5, y: 15), control2: CGPoint(x: 1, y: 12.5))
        p.addCurve(to: CGPoint(x: 5, y: 1), control1: CGPoint(x: 2.2, y: 7.2), control2: CGPoint(x: 4.6, y: 6))
        p.addCurve(to: CGPoint(x: 10.4, y: 10), control1: CGPoint(x: 7.6, y: 3.3), control2: CGPoint(x: 10.4, y: 6.4))
        p.addCurve(to: CGPoint(x: 6, y: 15), control1: CGPoint(x: 10.4, y: 13), control2: CGPoint(x: 8.6, y: 15))
        p.closeSubpath()
        let t = CGAffineTransform(scaleX: r.width / 12, y: r.height / 16)
        return p.applying(t).offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct FlamesRow: View {
    let stars: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(i < stars ? Pal.gold : Pal.line)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(stars) de 3")
    }
}

struct ProgressBar: View {
    let value: Double
    var tint: Color = Pal.gold
    var height: CGFloat = 6
    var track: Color = Pal.line.opacity(0.7)

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: max(0, min(1, value)) * g.size.width)
            }
        }
        .frame(height: height)
    }
}

struct Ring: View {
    let value: Double
    let tint: Color
    var body: some View {
        ZStack {
            Circle().stroke(Pal.line, lineWidth: 5)
            Circle()
                .trim(from: 0, to: value)
                .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((value * 100).rounded()))%")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Pal.fg)
        }
        .frame(width: 52, height: 52)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Balão de fala da Lumi.
struct Bubble<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .font(.callout)
            .foregroundStyle(Pal.fg)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Pal.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Triangle().fill(Pal.bubble).frame(width: 14, height: 14).offset(x: 7)
            }
            .shadow(color: .black.opacity(0.28), radius: 16, y: 10)
    }
}

/// Quebra de linha automática para as palavras do jogo e para o título.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, w: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 {
                y += lineH + lineSpacing
                x = 0
                lineH = 0
            }
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
            w = max(w, x - spacing)
        }
        return CGSize(width: w, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX {
                y += lineH + lineSpacing
                x = bounds.minX
                lineH = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
        }
    }
}

/// Título com as letras subindo uma a uma, a partir do centro (toque para repetir).
struct RollingTitle: View {
    let text: String
    var font: Font = .display(.largeTitle)
    var color: Color = .white
    @State private var go = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ text: String, font: Font = .display(.largeTitle), color: Color = .white) {
        self.text = text
        self.font = font
        self.color = color
    }

    private var offsets: [Int] {
        var r: [Int] = []
        var run = 0
        for w in text.split(separator: " ") {
            r.append(run)
            run += w.count + 1
        }
        return r
    }

    var body: some View {
        let mid = Double(text.count - 1) / 2
        let words = text.split(separator: " ").map(String.init)
        let offsets = self.offsets

        FlowLayout(spacing: 11, lineSpacing: 2) {
            ForEach(Array(words.enumerated()), id: \.offset) { wi, w in
                HStack(spacing: 0) {
                    ForEach(Array(w.enumerated()), id: \.offset) { ci, ch in
                        let dist = abs(Double(offsets[wi] + ci) - mid)
                        Text(String(ch))
                            .font(font)
                            .foregroundStyle(color)
                            .offset(y: go || reduceMotion ? 0 : 30)
                            .opacity(go || reduceMotion ? 1 : 0)
                            .blur(radius: go || reduceMotion ? 0 : 4)
                            .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(dist * 0.04), value: go)
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
        .onAppear { go = true }
        .onTapGesture {
            go = false
            Task {
                try? await Task.sleep(nanoseconds: 80_000_000)
                go = true
            }
        }
    }
}

private struct Spark: Identifiable {
    let id = UUID()
    let x = Double.random(in: 0...1)
    let delay = Double.random(in: 0...0.6)
    let dur = Double.random(in: 1.6...2.8)
    let dx = Double.random(in: -40...40)
    let rot = Double.random(in: 0...360)
}

/// Chuva de chamas douradas na comemoração.
struct Confetti: View {
    @State private var start = Date()
    @State private var sparks = (0..<26).map { _ in Spark() }

    var body: some View {
        TimelineView(.animation) { tl in
            GeometryReader { g in
                let t = tl.date.timeIntervalSince(start)
                ForEach(sparks) { p in
                    let u = (t - p.delay) / p.dur
                    if u > 0 && u < 1 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Pal.gold)
                            .rotationEffect(.degrees(p.rot + u * 180))
                            .position(x: p.x * g.size.width + p.dx * u, y: -20 + u * (g.size.height + 40))
                            .opacity(1 - max(0, (u - 0.75) * 4))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Faixa colorida do topo das telas internas (título e Lumi).
struct HeroBackground: View {
    let theme: Theme
    var body: some View {
        GlowBackground(theme: theme)
            .overlay(alignment: .top) {
                LinearGradient(colors: [theme.deep, theme.deep.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 70)
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 34, bottomTrailingRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }
}
