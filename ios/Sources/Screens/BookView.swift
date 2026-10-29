import SwiftUI

struct BookView: View {
    let book: Book
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var nav: Nav
    @State private var poke: Int? = nil
    @State private var pokeRev = false

    private var theme: Theme { Theme.of(book.id) }

    var body: some View {
        let line = Lines.book(book, store)
        ScrollView {
            VStack(spacing: 0) {
                hero(line)
                VStack(spacing: 26) {
                    weekCard
                    continueCard
                    lessons
                    church
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 44)
            }
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: false)
    }

    // MARK: topo
    private func hero(_ line: (mood: LumiMood, text: String)) -> some View {
        let p = store.pctOf(book)
        let learned = store.learned(book)
        let days = store.daysCount
        let mood: LumiMood = {
            if let n = poke { _ = n; return pokeRev ? (book.isConf ? .happy : .cheer) : .think }
            return line.mood
        }()
        return VStack(alignment: .leading, spacing: 12) {
            Text(book.tag.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(Pal.brightGold)
            RollingTitle(book.full, font: .display(.title))
            Text(book.sub)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 8) {
                Bubble { speech(line) }
                    .padding(.bottom, 34)
                Button { doPoke() } label: {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Pal.brightGold.opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 80))
                            .frame(width: 170, height: 170)
                        LumiView(mood: mood)
                            .frame(width: 118, height: 140)
                    }
                    .frame(width: 124, height: 150)
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Pedir uma \(book.isConf ? "seção" : "pergunta") surpresa à Lumi")
            }
            .padding(.top, 4)

            HStack(spacing: 8) {
                StatChip(value: "\(p)%", label: "do livro")
                StatChip(value: "\(learned)", label: "de \(book.items.count) praticad\(book.isConf ? "as" : "as")")
                StatChip(value: "\(days)", label: days == 1 ? "dia de estudo" : "dias de estudo")
            }
            ProgressBar(value: Double(p) / 100, tint: Pal.brightGold, height: 7, track: .white.opacity(0.18))
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { HeroBackground(theme: theme) }
    }

    @ViewBuilder
    private func speech(_ line: (mood: LumiMood, text: String)) -> some View {
        if let n = poke {
            let x = book.item(n)
            VStack(alignment: .leading, spacing: 8) {
                if !pokeRev {
                    if book.isConf {
                        Text(md("\(x.label), **\(x.q)**. Lembra o que diz?"))
                    } else {
                        Text(md("\(book.id == "breve" ? "Você lembra a" : "Responda:") pergunta \(n)?\n**\(x.q)**"))
                    }
                    Button(book.isConf ? "Mostrar o texto" : "Mostrar resposta") { pokeRev = true }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.accent)
                } else {
                    Text(md((book.isConf ? "" : "**\(n).** ") + TextTools.trunc(x.a, 200)))
                    Button(book.isConf ? "Outra seção" : "Outra pergunta") { doPoke() }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        } else {
            Text(md(line.text))
        }
    }

    private func doPoke() {
        var n = book.all.randomElement() ?? 1
        while let p = poke, n == p, book.items.count > 1 { n = book.all.randomElement() ?? 1 }
        poke = n
        pokeRev = false
        Haptics.tap()
    }

    // MARK: pergunta da semana
    private var weekCard: some View {
        let wk = Lines.week(book)
        let w = book.item(wk.n)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(book.itemWord) da semana · \(wk.label)".uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(Pal.muted)
                Spacer()
                Text(book.isConf ? "\(w.ch ?? 0).\(w.sec ?? 0)" : "\(wk.n)")
                    .font(.display(.title))
                    .foregroundStyle(Pal.gold)
            }
            Text(book.isConf ? "\(w.label.components(separatedBy: " · ").first ?? ""): \(w.q)" : w.q)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Pal.fg)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button(book.isConf ? "Ler" : "Estudar") {
                    let u = book.unitOf(wk.n)
                    store.setLast(book.id, u)
                    nav.push(.study(book.id, u, wk.n - book.units[u].a))
                }
                .buttonStyle(PillStyle(kind: .solid))
                Button("Projetar na classe") {
                    let u = book.unitOf(wk.n)
                    nav.push(.classroom(book.id, u, wk.n - book.units[u].a))
                }
                .buttonStyle(PillStyle(kind: .plain))
            }
        }
        .padding(16)
        .card()
    }

    @ViewBuilder
    private var continueCard: some View {
        if let last = store.last(book.id), last < book.units.count {
            let list = book.nums(last)
            Button { nav.push(.unit(book.id, last)) } label: {
                HStack(spacing: 14) {
                    Text("\(book.unitNum(last))")
                        .font(.display(.title2))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(theme.primary, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CONTINUAR")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.4)
                            .foregroundStyle(Pal.muted)
                        Text(book.units[last].t)
                            .font(.headline)
                            .foregroundStyle(Pal.fg)
                            .multilineTextAlignment(.leading)
                        Text("\(book.unitRange(last)) · \(store.pct(book, list))% dominado")
                            .font(.footnote)
                            .foregroundStyle(Pal.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").foregroundStyle(Pal.muted)
                }
                .padding(14)
                .card()
            }
            .buttonStyle(PressStyle())
        }
    }

    // MARK: lições
    private var lessons: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(book.isConf ? "Capítulos" : "Lições", trailing: "3 chamas = \(book.isConf ? "seção" : "pergunta") dominada")
            VStack(spacing: 0) {
                ForEach(Array(book.units.enumerated()), id: \.offset) { i, u in
                    Button { nav.push(.unit(book.id, i)) } label: {
                        HStack(spacing: 14) {
                            Text("\(book.unitNum(i))")
                                .font(.display(.headline))
                                .foregroundStyle(theme.accent)
                                .frame(width: 40, height: 40)
                                .background(theme.soft, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(u.t)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Pal.fg)
                                    .multilineTextAlignment(.leading)
                                Text(book.unitRange(i))
                                    .font(.footnote)
                                    .foregroundStyle(Pal.muted)
                                ProgressBar(value: Double(store.pct(book, book.nums(i))) / 100, tint: theme.accent, height: 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Pal.muted)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle())
                    if i < book.units.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .card()
        }
    }

    private var church: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Na igreja")
            Button { nav.push(.classroom(book.id, store.last(book.id) ?? 0, 0)) } label: {
                ToolTile(title: "Modo Classe", subtitle: "Projetar, revelar e marcar pontos por equipe.", icon: "rectangle.on.rectangle.angled", primary: true)
            }
            .buttonStyle(PressStyle())
            Button {
                nav.startGame(book, pool: book.all, mode: .mix, back: .book, store: store)
            } label: {
                ToolTile(title: "Revisão geral", subtitle: "8 \(book.isConf ? "seções" : "perguntas") sorteadas de todo o livro.", icon: "shuffle", primary: false)
            }
            .buttonStyle(PressStyle())
        }
    }
}

struct StatChip: View {
    let value: String
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Text(value).font(.footnote.weight(.bold))
            Text(label).font(.caption2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}
