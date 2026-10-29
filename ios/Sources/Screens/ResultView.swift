import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var nav: Nav
    @EnvironmentObject private var store: Store

    var body: some View {
        if let g = nav.game {
            content(g)
        } else {
            Color.clear
        }
    }

    private func content(_ g: Game) -> some View {
        let theme = Theme.of(g.book.id)
        let t = g.items.count
        let r = Double(g.ok) / Double(max(1, t))
        let msg: String = {
            switch g.book.id {
            case "maior": return r == 1 ? "Excelente. Todas as respostas firmes." : r >= 0.6 ? "Bom estudo. Mais uma rodada consolida." : "Vale reler as respostas com calma e tentar de novo."
            case "conf": return r == 1 ? "Muito bem. Você conhece bem estes textos." : r >= 0.6 ? "Bom. Uma nova leitura deixa tudo mais claro." : "Vale reler o capítulo com calma e tentar de novo."
            default: return r == 1 ? "Perfeito! Você sabe estas respostas." : r >= 0.6 ? "Muito bom. Mais uma rodada e fica firme." : "Vale estudar as respostas e tentar de novo."
            }
        }()
        let mood = g.shown(r >= 0.8 ? .cheer : r >= 0.5 ? .happy : .sad)

        return ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    LumiView(mood: mood)
                        .frame(height: 170)
                    Text("\(g.ok)/\(t)")
                        .font(.system(size: 64, weight: .bold, design: .serif))
                        .foregroundStyle(theme.accent)
                    Text(msg)
                        .font(.display(.title3))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Pal.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .card(radius: 26)

                VStack(spacing: 0) {
                    ForEach(Array(g.items.enumerated()), id: \.offset) { i, it in
                        let x = g.book.item(it.n)
                        HStack(spacing: 12) {
                            Text(g.book.isConf ? "\(x.ch ?? 0).\(x.sec ?? 0)" : "\(it.n)")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(theme.accent)
                                .frame(minWidth: 34, minHeight: 34)
                                .background(theme.soft, in: Capsule())
                            Text(x.q)
                                .font(.callout)
                                .foregroundStyle(Pal.fg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            FlamesRow(stars: store.stars(g.book.id, it.n))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        if i < g.items.count - 1 { Divider().padding(.leading, 60) }
                    }
                }
                .card()

                HStack(spacing: 10) {
                    Button("Jogar de novo") { nav.again(store: store) }
                        .buttonStyle(PillStyle(kind: .solid))
                    if g.back == .book {
                        Button("Voltar ao livro") { nav.popToBook() }
                            .buttonStyle(PillStyle(kind: .plain))
                    } else {
                        Button(g.book.isConf ? "Ler o capítulo" : "Estudar a lição") { nav.studyFromResult(g) }
                            .buttonStyle(PillStyle(kind: .plain))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "Resultado")
        .overlay { if r >= 0.8 { Confetti() } }
    }
}
