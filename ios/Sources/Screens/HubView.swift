import SwiftUI

struct HubView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav

    private let theme = Theme.breve

    var body: some View {
        let line = Lines.hub(store)
        ScrollView {
            VStack(spacing: 0) {
                hero(line)
                VStack(spacing: 28) {
                    shelf
                    church
                    texts
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 26)
                .padding(.bottom, 44)
            }
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: false)
    }

    private func hero(_ line: (mood: LumiMood, text: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WESTMINSTER · EM JOGOS")
                .font(.caption.weight(.semibold))
                .tracking(2.4)
                .foregroundStyle(Pal.brightGold)
            RollingTitle("Lumi Catecismos", font: .display(.largeTitle))
            Text("O Breve Catecismo, o Catecismo Maior e a Confissão de Fé, para aprender em casa e ensinar na igreja.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
            BooksScene { id in open(id) }
                .padding(.top, 6)
            Bubble { Text(md(line.text)) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { HeroBackground(theme: theme) }
    }

    private var shelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Os três livros", trailing: "Toque para abrir")
            ForEach(Library.order, id: \.self) { id in
                bookCard(id)
            }
        }
    }

    private func bookCard(_ id: String) -> some View {
        let b = Library.book(id)
        let t = Theme.of(id)
        let p = Double(store.pctOf(b)) / 100
        let wk = Lines.week(b)
        let weekText = b.isConf ? b.item(wk.n).label : "\(wk.n)"
        return Button { open(id) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(colors: [t.spine, t.spine.opacity(0.75)], startPoint: .leading, endPoint: .trailing))
                    VStack {
                        Rectangle().fill(Pal.brightGold).frame(height: 2)
                        Spacer()
                        Rectangle().fill(Pal.brightGold).frame(height: 2)
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: 14, height: 84)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(b.tag.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(Pal.muted)
                    Text(b.name)
                        .font(.display(.title3))
                        .foregroundStyle(Pal.fg)
                    Text(b.countsLine)
                        .font(.footnote)
                        .foregroundStyle(Pal.muted)
                    Text("\(b.itemWord) da semana: \(weekText)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(t.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Ring(value: p, tint: t.accent)
            }
            .padding(14)
            .card()
        }
        .buttonStyle(PressStyle())
    }

    private var church: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Na igreja")
            Button {
                let id = store.lastBook ?? "breve"
                store.setLastBook(id)
                nav.push(.classroom(id, store.last(id) ?? 0, 0))
            } label: {
                ToolTile(title: "Modo Classe", subtitle: "Projetar perguntas de qualquer livro, revelar respostas e marcar pontos por equipe.", icon: "rectangle.on.rectangle.angled", primary: true)
            }
            .buttonStyle(PressStyle())
        }
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Textos para decorar")
            VStack(spacing: 10) {
                textRow("mand", "Dez Mandamentos", "Êx 20.3-17")
                textRow("pai", "Pai Nosso", "Mt 6.9-13")
                textRow("credo", "Credo", "Credo Apostólico")
            }
        }
    }

    private func textRow(_ key: String, _ title: String, _ sub: String) -> some View {
        Button { nav.push(.text(key)) } label: {
            ToolTile(title: title, subtitle: sub, icon: "book.closed", primary: false)
        }
        .buttonStyle(PressStyle())
    }

    private var footer: some View {
        VStack(spacing: 10) {
            LumiView(mood: .happy, pose: .sarca)
                .frame(height: 130)
            Text("Funciona sem internet.\nO progresso de cada livro fica salvo neste aparelho.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Pal.muted)
            Text("Lumi Catecismos · Padrões de Westminster")
                .font(.system(.footnote, design: .serif).italic())
                .foregroundStyle(Pal.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private func open(_ id: String) {
        store.setLastBook(id)
        nav.push(.book(id))
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.display(.title2)).foregroundStyle(Pal.fg)
            Spacer()
            if let t = trailing {
                Text(t).font(.footnote).foregroundStyle(Pal.muted)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct ToolTile: View {
    let title: String
    let subtitle: String
    let icon: String
    var primary = false
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(primary ? .white : theme.accent)
                .frame(width: 44, height: 44)
                .background(primary ? AnyShapeStyle(.white.opacity(0.18)) : AnyShapeStyle(theme.soft), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(primary ? .white : Pal.fg)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(primary ? .white.opacity(0.85) : Pal.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(primary ? .white.opacity(0.7) : Pal.muted)
        }
        .padding(14)
        .background {
            if primary {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [theme.primary.opacity(0.88), theme.primary], startPoint: .top, endPoint: .bottom))
                    .shadow(color: theme.primary.opacity(0.4), radius: 14, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Pal.surface)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Pal.line.opacity(0.7), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            }
        }
    }
}
