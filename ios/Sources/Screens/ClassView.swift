import SwiftUI
import UIKit

/// Modo Classe: perguntas grandes para projetar, respostas reveladas e placar por equipe.
/// Na horizontal, a barra some, a pergunta e a resposta ficam lado a lado e os controles cabem numa linha só.
struct ClassView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.dismiss) private var dismiss
    @State private var bookID: String
    @State private var u: Int
    @State private var idx: Int
    @State private var rev = false
    @State private var picking = false

    init(startBook: String, startUnit: Int, startIndex: Int) {
        _bookID = State(initialValue: startBook)
        _u = State(initialValue: startUnit)
        _idx = State(initialValue: startIndex)
    }

    private var book: Book { Library.book(bookID) }
    private var theme: Theme { Theme.of(bookID) }
    private var compact: Bool { vSize == .compact }

    var body: some View {
        let list = book.nums(u)
        let i = min(idx, list.count - 1)
        let x = book.item(list[i])
        ZStack {
            GlowBackground(theme: theme).ignoresSafeArea()
            VStack(spacing: 0) {
                stage(x)
                if store.d.scoreOn { scoreboard }
                controls(list, i, x)
            }
        }
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "Modo Classe · \(i + 1)/\(list.count)")
        .toolbar(compact ? .hidden : .visible, for: .navigationBar)
        .sheet(isPresented: $picking) {
            ClassPicker(bookID: bookID, u: u, current: x.n) { id, unit, n in
                if id != bookID { bookID = id; store.setLastBook(id) }
                u = unit
                let l = Library.book(id).nums(unit)
                idx = l.firstIndex(of: n) ?? 0
                rev = false
                picking = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if ProcessInfo.processInfo.arguments.contains("-classpick") { picking = true }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Speaker.shared.stop()
        }
    }

    // MARK: pergunta e resposta
    private func stage(_ x: Item) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 8 : 18) {
                HStack(alignment: .top) {
                    Text("\(book.name) · \(x.label)\(u >= 0 && !book.isConf ? " · Lição \(u + 1)" : "")".uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(Pal.brightGold)
                    Spacer()
                    LumiView(mood: rev ? .happy : .think)
                        .frame(width: compact ? 56 : 88, height: compact ? 64 : 100)
                }
                if compact {
                    HStack(alignment: .top, spacing: 22) {
                        question(x, size: .title)
                        if rev { answer(x) }
                    }
                } else {
                    question(x, size: .largeTitle)
                    if rev { answer(x) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, compact ? 8 : 16)
            .readable(1000)
        }
    }

    private func question(_ x: Item, size: Font.TextStyle) -> some View {
        Text(x.q)
            .font(.system(size, design: .serif).weight(.bold))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func answer(_ x: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(x.a)
                .font(.system(compact ? .title3 : .title2, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(.white)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
            if !x.r.isEmpty {
                Text(x.r).font(.footnote).foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: placar
    private var scoreboard: some View {
        HStack(spacing: 10) {
            team("Equipe 1", store.d.scoreA, 0)
            team("Equipe 2", store.d.scoreB, 1)
            Button { store.zeroScore() } label: { Image(systemName: "arrow.counterclockwise") }
                .buttonStyle(IconPillStyle())
                .accessibilityLabel("Zerar placar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 6 : 10)
        .background(.black.opacity(0.3))
    }

    private func team(_ name: String, _ score: Int, _ t: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 10) {
                Button { store.addScore(team: t, delta: -1) } label: { Image(systemName: "minus") }
                    .buttonStyle(IconPillStyle())
                    .accessibilityLabel("Tirar ponto da \(name)")
                Text("\(score)")
                    .font(.system(size: compact ? 28 : 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .frame(minWidth: 40)
                Button { store.addScore(team: t, delta: 1); Haptics.tap() } label: { Image(systemName: "plus") }
                    .buttonStyle(IconPillStyle(solid: true))
                    .accessibilityLabel("Ponto para a \(name)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: controles
    private func controls(_ list: [Int], _ i: Int, _ x: Item) -> some View {
        Group {
            if compact {
                HStack(spacing: 8) {
                    backButton
                    chooseButton(x)
                    prevButton(i)
                    revealButton
                    shuffleButton(list.count, i)
                    nextButton(list.count, i)
                    scoreButton
                    speakButton(x)
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        chooseButton(x)
                        Spacer(minLength: 0)
                        scoreButton
                        speakButton(x)
                    }
                    HStack(spacing: 8) {
                        prevButton(i)
                        revealButton
                        shuffleButton(list.count, i)
                        nextButton(list.count, i)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 6 : 12)
        .background(.black.opacity(0.35))
    }

    private var backButton: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            .buttonStyle(IconPillStyle())
            .accessibilityLabel("Voltar")
    }

    /// Um botão só para escolher livro, lição e a pergunta exata.
    private func chooseButton(_ x: Item) -> some View {
        Button { picking = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "list.number").font(.subheadline.weight(.bold))
                VStack(alignment: .leading, spacing: 0) {
                    Text(book.short + (u < 0 ? " · livro todo" : " · \(book.unitWord) \(book.unitNum(u))"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Pal.muted)
                    Text("\(book.itemWord) \(book.isConf ? "\(x.ch ?? 0).\(x.sec ?? 0)" : "\(x.n)")")
                        .font(.subheadline.weight(.bold))
                }
                .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.caption2)
            }
            .foregroundStyle(Pal.fg)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Pal.surface, in: Capsule())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Escolher livro, lição e pergunta")
    }

    private func prevButton(_ i: Int) -> some View {
        Button { move(-1, i) } label: { Image(systemName: "chevron.left") }
            .buttonStyle(IconPillStyle())
            .disabled(i == 0)
            .accessibilityLabel("Anterior")
    }

    private func nextButton(_ count: Int, _ i: Int) -> some View {
        Button { move(1, i, count) } label: { Image(systemName: "chevron.right") }
            .buttonStyle(IconPillStyle())
            .disabled(i >= count - 1)
            .accessibilityLabel("Próxima")
    }

    private var revealButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { rev.toggle() }
        } label: {
            Text(rev ? "Esconder" : "Revelar").frame(maxWidth: .infinity)
        }
        .buttonStyle(PillStyle(kind: .gold))
    }

    private func shuffleButton(_ count: Int, _ cur: Int) -> some View {
        Button { random(count, cur) } label: { Image(systemName: "shuffle") }
            .buttonStyle(IconPillStyle())
            .accessibilityLabel("Sortear")
    }

    private var scoreButton: some View {
        Button { store.toggleScore() } label: { Image(systemName: "trophy.fill") }
            .buttonStyle(IconPillStyle(solid: store.d.scoreOn))
            .accessibilityLabel(store.d.scoreOn ? "Esconder placar" : "Mostrar placar")
    }

    private func speakButton(_ x: Item) -> some View {
        Button { Speaker.shared.say("\(x.q). \(x.a)") } label: { Image(systemName: "speaker.wave.2.fill") }
            .buttonStyle(IconPillStyle())
            .accessibilityLabel("Ouvir")
    }

    // MARK: ações
    private func move(_ d: Int, _ cur: Int, _ count: Int = Int.max) {
        let n = cur + d
        guard n >= 0, n < count else { return }
        idx = n
        rev = false
    }

    private func random(_ count: Int, _ cur: Int) {
        guard count > 1 else { return }
        var n = cur
        while n == cur { n = Int.random(in: 0..<count) }
        idx = n
        rev = false
    }
}

/// Tela de escolha do Modo Classe: livro, lição (ou livro todo) e o número exato da pergunta.
struct ClassPicker: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State var bookID: String
    let origin: String
    let u: Int
    let current: Int
    let choose: (String, Int, Int) -> Void

    init(bookID: String, u: Int, current: Int, choose: @escaping (String, Int, Int) -> Void) {
        _bookID = State(initialValue: bookID)
        origin = bookID
        self.u = u
        self.current = current
        self.choose = choose
    }

    private var book: Book { Library.book(bookID) }
    private var theme: Theme { Theme.of(bookID) }
    private let cols = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        Picker("Livro", selection: $bookID) {
                            ForEach(Library.order, id: \.self) { id in Text(Library.book(id).short).tag(id) }
                        }
                        .pickerStyle(.segmented)

                        Button { choose(bookID, -1, book.all.first ?? 1) } label: {
                            HStack {
                                Image(systemName: "books.vertical.fill")
                                Text("Livro inteiro, em ordem").font(.body.weight(.semibold))
                                Spacer()
                                Text(book.countsLine).font(.footnote).foregroundStyle(Pal.muted)
                            }
                            .padding(14)
                            .card(radius: 16)
                        }
                        .buttonStyle(PressStyle())

                        ForEach(Array(book.units.enumerated()), id: \.offset) { k, un in
                            unitBlock(k, un).id(k)
                        }
                    }
                    .padding(16)
                    .readable(760)
                }
                .onAppear {
                    if u >= 0 { proxy.scrollTo(u, anchor: .top) }
                }
            }
            .background(Pal.bg.ignoresSafeArea())
            .navigationTitle("Escolher pergunta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
            }
        }
        .environment(\.theme, theme)
        .tint(theme.accent)
    }

    private func unitBlock(_ k: Int, _ un: Unit) -> some View {
        let here = bookID == origin && (u < 0 || k == u)
        return VStack(alignment: .leading, spacing: 10) {
            Button { choose(bookID, k, un.a) } label: {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(book.unitWord.uppercased()) \(book.unitNum(k))")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(theme.accent)
                        Text(un.t)
                            .font(.display(.headline))
                            .foregroundStyle(Pal.fg)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Text("Começar")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(un.a...un.b, id: \.self) { n in
                    let x = book.item(n)
                    let on = n == current && here
                    Button { choose(bookID, k, n) } label: {
                        Text(book.isConf ? "\(x.ch ?? 0).\(x.sec ?? 0)" : "\(n)")
                            .font(.callout.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(on ? Pal.bg : Pal.fg)
                            .background(on ? theme.accent : theme.soft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel("\(book.itemWord) \(x.label)")
                }
            }
        }
        .padding(14)
        .card(radius: 18)
    }
}
