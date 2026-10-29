import SwiftUI

struct UnitView: View {
    let book: Book
    let u: Int
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav

    private var theme: Theme { Theme.of(book.id) }

    var body: some View {
        let list = book.nums(u)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(list)
                tools(list)
                questions(list)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "\(book.unitWord) \(book.unitNum(u))")
        .onAppear { store.setLast(book.id, u) }
    }

    private func header(_ list: [Int]) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(book.name) · \(book.unitWord) \(book.unitNum(u)) · \(book.unitRange(u))".uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(Pal.muted)
                Text(book.units[u].t)
                    .font(.display(.title))
                    .foregroundStyle(Pal.fg)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    ProgressBar(value: Double(store.pct(book, list)) / 100, tint: theme.accent, height: 6)
                    Text("\(store.pct(book, list))%").font(.footnote.weight(.semibold)).foregroundStyle(theme.accent)
                }
            }
            LumiView(mood: .idle)
                .frame(width: 84, height: 96)
        }
    }

    private func tools(_ list: [Int]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(spacing: 12) {
            Button { nav.push(.study(book.id, u, 0)) } label: {
                ToolTile(title: book.isConf ? "Ler" : "Estudar", subtitle: book.isConf ? "Ler e ouvir cada seção do capítulo." : "Ler, ouvir e revelar cada resposta.", icon: "book.fill", primary: true)
            }
            .buttonStyle(PressStyle())
            LazyVGrid(columns: columns, spacing: 12) {
                gameTile("Quiz", book.isConf ? "De qual capítulo é este trecho?" : "Escolha a resposta certa.", "checklist", .quiz, list)
                gameTile("Completar", "Encaixe as palavras que faltam.", "text.badge.checkmark", .complete, list)
                gameTile("Montar", "Coloque os trechos na ordem.", "list.number", .build, list)
                gameTile("Desafio", "Tudo misturado, para fixar.", "flame.fill", .mix, list)
            }
        }
    }

    private func gameTile(_ title: String, _ sub: String, _ icon: String, _ mode: PlayMode, _ list: [Int]) -> some View {
        Button { nav.startGame(book, pool: list, mode: mode, back: .unit, store: store) } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 40, height: 40)
                    .background(theme.soft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title).font(.headline).foregroundStyle(Pal.fg)
                Text(sub)
                    .font(.footnote)
                    .foregroundStyle(Pal.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .padding(14)
            .card()
        }
        .buttonStyle(PressStyle())
    }

    private func questions(_ list: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(book.isConf ? "Seções" : "Perguntas", trailing: "3 chamas = dominada")
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.offset) { i, n in
                    let x = book.item(n)
                    Button { nav.push(.study(book.id, u, i)) } label: {
                        HStack(spacing: 12) {
                            Text(book.isConf ? "\(x.sec ?? 0)" : "\(n)")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(theme.accent)
                                .frame(width: 34, height: 34)
                                .background(theme.soft, in: Circle())
                            Text(book.isConf ? TextTools.trunc(x.a, 90) : x.q)
                                .font(.callout)
                                .foregroundStyle(Pal.fg)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            FlamesRow(stars: store.stars(book.id, n))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle())
                    if i < list.count - 1 { Divider().padding(.leading, 60) }
                }
            }
            .card()
        }
    }
}
