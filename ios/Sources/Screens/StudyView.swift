import SwiftUI

struct StudyView: View {
    let book: Book
    let u: Int
    let start: Int
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav
    @State private var i: Int
    @State private var rev = false

    init(book: Book, u: Int, start: Int) {
        self.book = book
        self.u = u
        self.start = start
        _i = State(initialValue: start)
    }

    private var theme: Theme { Theme.of(book.id) }

    var body: some View {
        let list = book.nums(u)
        let idx = min(max(i, 0), list.count - 1)
        let x = book.item(list[idx])
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        Text(x.label.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1.2)
                            .foregroundStyle(Pal.muted)
                        Spacer()
                        LumiView(mood: rev ? .happy : .idle)
                            .frame(width: 78, height: 88)
                            .offset(y: -6)
                    }
                    Text(x.q)
                        .font(.display(.title2))
                        .foregroundStyle(Pal.fg)
                        .fixedSize(horizontal: false, vertical: true)

                    if rev {
                        Text(x.a)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Pal.fg)
                            .lineSpacing(5)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    HStack(spacing: 10) {
                        if !rev {
                            Button(book.isConf ? "Mostrar o texto" : "Mostrar resposta") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { rev = true }
                            }
                            .buttonStyle(PillStyle(kind: .solid))
                        }
                        Button {
                            Speaker.shared.say(rev ? "\(x.q). \(x.a)" : x.q)
                        } label: {
                            Label("Ouvir", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(PillStyle(kind: .plain))
                    }

                    if !x.r.isEmpty {
                        (Text("Referências: ").bold() + Text(x.r))
                            .font(.footnote)
                            .foregroundStyle(Pal.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .card(radius: 24)

                HStack(spacing: 12) {
                    Button { go(idx - 1) } label: { Label("Anterior", systemImage: "chevron.left") }
                        .buttonStyle(PillStyle(kind: .plain))
                        .disabled(idx == 0)
                    Spacer()
                    if idx < list.count - 1 {
                        Button { go(idx + 1) } label: {
                            HStack(spacing: 6) { Text("Próxima"); Image(systemName: "chevron.right") }
                        }
                        .buttonStyle(PillStyle(kind: .solid))
                    } else {
                        Button("Fazer o desafio") {
                            nav.startGame(book, pool: list, mode: .mix, back: .unit, store: store)
                        }
                        .buttonStyle(PillStyle(kind: .gold))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "\(idx + 1) de \(list.count)")
        .onAppear {
            store.setLast(book.id, u)
        }
        .onDisappear { Speaker.shared.stop() }
    }

    private func go(_ k: Int) {
        Speaker.shared.stop()
        withAnimation(.easeInOut(duration: 0.2)) {
            i = k
            rev = false
        }
    }
}
