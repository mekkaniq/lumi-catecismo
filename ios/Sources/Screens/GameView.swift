import SwiftUI

struct GameView: View {
    @EnvironmentObject private var nav: Nav

    var body: some View {
        if let g = nav.game {
            GameBody(g: g)
        } else {
            Color.clear
        }
    }
}

private struct GameBody: View {
    @ObservedObject var g: Game
    @EnvironmentObject private var nav: Nav
    @EnvironmentObject private var store: Store

    private var theme: Theme { Theme.of(g.book.id) }

    var body: some View {
        let x = g.item
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dots
                head(x)
                content(x)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, g.done ? 12 : 40)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "\(g.mode.title) · \(g.i + 1)/\(g.items.count)")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if g.done { feedback(x) }
        }
        .overlay { if g.done && g.mood == .cheer { Confetti() } }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: g.done)
        .onChange(of: g.finished) { _, f in
            if f { nav.finishGame() }
        }
    }

    // MARK: cabeçalho
    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<g.items.count, id: \.self) { k in
                Capsule()
                    .fill(k < g.i ? theme.accent : k == g.i ? Pal.gold : Pal.line)
                    .frame(height: 6)
            }
        }
    }

    private func head(_ x: Item) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                if g.isConfQuiz {
                    Text("\(g.book.name) · Quiz".uppercased()).eyebrow()
                    Text(g.done ? "\(x.label): \(x.q)" : "Reconheça o capítulo")
                        .font(.display(.title3)).foregroundStyle(Pal.fg)
                } else {
                    Text("\(x.label) · \(g.current.mode.title)".uppercased()).eyebrow()
                    Text(x.q).font(.display(.title3)).foregroundStyle(Pal.fg)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            LumiView(mood: g.live)
                .frame(width: 84, height: 96)
        }
    }

    // MARK: corpo de cada modo
    @ViewBuilder
    private func content(_ x: Item) -> some View {
        switch g.current.mode {
        case .quiz: quiz(x)
        case .complete: complete()
        default: build()
        }
    }

    private func quiz(_ x: Item) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if g.isConfQuiz {
                Text("“\(g.excerpt)…”")
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(Pal.fg)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("De qual capítulo é este trecho?").promptLabel()
            } else {
                Text("Qual é a resposta?").promptLabel()
            }
            ForEach(g.opts, id: \.self) { m in
                let right = g.book.isConf ? (m == x.ch) : (m == g.current.n)
                let state = !g.done ? 0 : right ? 1 : (m == g.chosen ? 2 : 0)
                Button { g.pickQuiz(m) } label: {
                    optionLabel(m, state: state)
                }
                .buttonStyle(PressStyle())
                .disabled(g.done)
            }
        }
    }

    private func optionLabel(_ m: Int, state: Int) -> some View {
        let text: Text
        if g.isConfQuiz {
            let u = g.book.units.first(where: { $0.ch == m })
            text = Text("Capítulo \(m)").bold() + Text(" · \(u?.t ?? "")")
        } else {
            text = Text(TextTools.trunc(g.book.item(m).a, 170))
        }
        return text
            .font(.callout)
            .foregroundStyle(Pal.fg)
            .multilineTextAlignment(.leading)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(state == 1 ? Pal.okBg : state == 2 ? Pal.badBg : Pal.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(state == 1 ? Pal.ok : state == 2 ? Pal.bad : Pal.line, lineWidth: state == 0 ? 1 : 2))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private var fillText: Text {
        var t = Text("")
        for (idx, w) in g.words.enumerated() {
            let space = idx == 0 ? "" : " "
            if let b = g.blanks.firstIndex(of: idx) {
                let filled = b < g.filled
                t = t + Text(space + TextTools.lead(w))
                if filled {
                    t = t + Text(TextTools.bare(w)).bold().foregroundColor(Pal.ok)
                } else {
                    t = t + Text("·····").bold().foregroundColor(b == g.filled ? theme.accent : Pal.muted)
                }
                t = t + Text(TextTools.trail(w))
            } else {
                t = t + Text(space + w)
            }
        }
        if g.cut { t = t + Text(" (continua…)").foregroundColor(Pal.muted) }
        return t
    }

    private func complete() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Complete \(g.book.isConf ? "o texto" : "a resposta") tocando nas palavras na ordem").promptLabel()
            fillText
                .font(.system(.title3, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(Pal.fg)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            if !g.done {
                FlowLayout(spacing: 10, lineSpacing: 10) {
                    ForEach(Array(g.bank.enumerated()), id: \.element.id) { k, b in
                        let wrong = g.wrongChip == b.id
                        Button { g.pickChip(k) } label: {
                            Text(b.w)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Pal.fg)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(wrong ? Pal.badBg : Pal.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(wrong ? Pal.bad : Pal.line, lineWidth: 1.5))
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                        .buttonStyle(PressStyle())
                        .disabled(b.used)
                        .opacity(b.used ? 0.25 : 1)
                    }
                }
            }
            missLine
        }
    }

    private func build() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Monte \(g.book.isConf ? "o início do texto" : "a resposta") tocando nos trechos na ordem").promptLabel()
            if !g.placed.isEmpty {
                Text(g.placed.map { g.chunks[$0] }.joined(separator: " "))
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(6)
                    .foregroundStyle(Pal.ok)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            }
            if !g.done {
                VStack(spacing: 10) {
                    ForEach(g.order.filter { !g.placed.contains($0) }, id: \.self) { k in
                        let wrong = g.wrongChunk == k
                        Button { g.pickChunk(k) } label: {
                            Text(g.chunks[k])
                                .font(.callout)
                                .foregroundStyle(Pal.fg)
                                .multilineTextAlignment(.leading)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(wrong ? Pal.badBg : Pal.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(wrong ? Pal.bad : Pal.line, lineWidth: 1.5))
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                        .buttonStyle(PressStyle())
                    }
                }
            }
            missLine
        }
    }

    @ViewBuilder
    private var missLine: some View {
        if g.miss > 0 {
            Text("\(g.miss) tentativa\(g.miss > 1 ? "s" : "") errada\(g.miss > 1 ? "s" : "")")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Pal.bad)
        }
    }

    // MARK: resposta (rodapé)
    private func feedback(_ x: Item) -> some View {
        let m = g.mood ?? .cheer
        let tint: Color = m == .sad ? Pal.bad : m == .meh ? Pal.gold : Pal.ok
        let title: String = m == .cheer ? (g.tone.praise.randomElement() ?? "Muito bem!") : m == .meh ? (g.correct ? g.tone.mehOk : g.tone.meh) : g.tone.sad
        let showAnswer = !(m == .cheer && g.current.mode != .quiz)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.display(.title3)).foregroundStyle(tint)
                    if showAnswer {
                        ScrollView {
                            Text(md((g.book.isConf ? "**\(x.label).** " : "**\(g.current.n).** ") + x.a))
                                .font(.callout)
                                .foregroundStyle(Pal.fg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    if !x.r.isEmpty {
                        Text(x.r).font(.footnote).foregroundStyle(Pal.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                LumiView(mood: g.live)
                    .frame(width: 66, height: 78)
            }
            HStack(spacing: 10) {
                Button(g.i < g.items.count - 1 ? "Continuar" : "Ver resultado") { g.next() }
                    .buttonStyle(PillStyle(kind: .solid))
                Button {
                    Speaker.shared.say("\(x.q). \(x.a)")
                } label: {
                    Label("Ouvir", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(PillStyle(kind: .plain))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Pal.surface.shadow(.drop(color: .black.opacity(0.18), radius: 14, y: -4)))
        .overlay(alignment: .top) { Rectangle().fill(tint).frame(height: 3) }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private extension Text {
    func eyebrow() -> some View {
        self.font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(Pal.muted)
    }
    func promptLabel() -> some View {
        self.font(.subheadline.weight(.medium)).foregroundStyle(Pal.muted)
    }
}
