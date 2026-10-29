import SwiftUI
import UIKit

/// Modo Classe: perguntas grandes para projetar, respostas reveladas e placar por equipe.
struct ClassView: View {
    @EnvironmentObject private var store: Store
    @State private var bookID: String
    @State private var u: Int
    @State private var idx: Int
    @State private var rev = false

    init(startBook: String, startUnit: Int, startIndex: Int) {
        _bookID = State(initialValue: startBook)
        _u = State(initialValue: startUnit)
        _idx = State(initialValue: startIndex)
    }

    private var book: Book { Library.book(bookID) }
    private var theme: Theme { Theme.of(bookID) }

    var body: some View {
        let list = book.nums(u)
        let i = min(idx, list.count - 1)
        let x = book.item(list[i])
        ZStack {
            GlowBackground(theme: theme).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            Text("\(book.name) · \(x.label)\(u >= 0 && !book.isConf ? " · Lição \(u + 1)" : "")".uppercased())
                                .font(.caption.weight(.semibold))
                                .tracking(1.4)
                                .foregroundStyle(Pal.brightGold)
                            Spacer()
                            LumiView(mood: rev ? .happy : .think)
                                .frame(width: 88, height: 100)
                        }
                        Text(x.q)
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                        if rev {
                            Text(x.a)
                                .font(.system(.title2, design: .serif))
                                .lineSpacing(6)
                                .foregroundStyle(.white)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            if !x.r.isEmpty {
                                Text(x.r).font(.footnote).foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                if store.d.scoreOn { scoreboard }
                controls(list, i, x)
            }
        }
        .environment(\.theme, theme)
        .lumiBar(theme, solid: false, title: "Modo Classe · \(i + 1)/\(list.count)")
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Speaker.shared.stop()
        }
    }

    // MARK: placar
    private var scoreboard: some View {
        HStack(spacing: 10) {
            team("Equipe 1", store.d.scoreA, 0)
            team("Equipe 2", store.d.scoreB, 1)
            Button("Zerar") { store.zeroScore() }
                .buttonStyle(PillStyle(kind: .plain))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.3))
    }

    private func team(_ name: String, _ score: Int, _ t: Int) -> some View {
        VStack(spacing: 6) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 10) {
                Button { store.addScore(team: t, delta: -1) } label: { Image(systemName: "minus") }
                    .buttonStyle(PillStyle(kind: .plain))
                    .accessibilityLabel("Tirar ponto da \(name)")
                Text("\(score)")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .frame(minWidth: 40)
                Button { store.addScore(team: t, delta: 1); Haptics.tap() } label: { Image(systemName: "plus") }
                    .buttonStyle(PillStyle(kind: .solid))
                    .accessibilityLabel("Ponto para a \(name)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: controles
    private func controls(_ list: [Int], _ i: Int, _ x: Item) -> some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Menu {
                        ForEach(Library.order, id: \.self) { id in
                            Button(Library.book(id).name) { switchBook(id) }
                        }
                    } label: { menuLabel(book.name) }
                    Menu {
                        Button("Livro inteiro") { u = -1; idx = 0; rev = false }
                        ForEach(Array(book.units.enumerated()), id: \.offset) { k, un in
                            Button("\(book.unitWord) \(book.unitNum(k)) · \(TextTools.trunc(un.t, 40))") { u = k; idx = 0; rev = false }
                        }
                    } label: { menuLabel(u < 0 ? "Livro inteiro" : "\(book.unitWord) \(book.unitNum(u))") }
                    Button { store.toggleScore() } label: {
                        Label(store.d.scoreOn ? "Esconder placar" : "Placar", systemImage: "scoreboard")
                    }
                    .buttonStyle(PillStyle(kind: .plain))
                    Button { Speaker.shared.say("\(x.q). \(x.a)") } label: {
                        Label("Ouvir", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(PillStyle(kind: .plain))
                }
                .padding(.horizontal, 16)
            }
            HStack(spacing: 10) {
                Button { move(-1, list.count) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(PillStyle(kind: .plain))
                    .disabled(i == 0)
                    .accessibilityLabel("Anterior")
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { rev.toggle() }
                } label: {
                    Text(rev ? "Esconder" : "Revelar").frame(maxWidth: .infinity)
                }
                .buttonStyle(PillStyle(kind: .gold))
                Button { random(list.count, i) } label: { Image(systemName: "shuffle") }
                    .buttonStyle(PillStyle(kind: .plain))
                    .accessibilityLabel("Sortear")
                Button { move(1, list.count) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(PillStyle(kind: .plain))
                    .disabled(i >= list.count - 1)
                    .accessibilityLabel("Próxima")
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(.black.opacity(0.35))
    }

    private func menuLabel(_ t: String) -> some View {
        HStack(spacing: 6) {
            Text(t).lineLimit(1)
            Image(systemName: "chevron.up.chevron.down").font(.caption)
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(Pal.fg)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Pal.surface, in: Capsule())
    }

    private func switchBook(_ id: String) {
        bookID = id
        u = store.last(id) ?? 0
        idx = 0
        rev = false
        store.setLastBook(id)
    }

    private func move(_ d: Int, _ count: Int) {
        let n = idx + d
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
