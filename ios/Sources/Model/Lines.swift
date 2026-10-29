import Foundation

/// Falas da Lumi (capa geral e cada livro), com o tom de cada um. **negrito** vira destaque.
@MainActor
enum Lines {
    static func greet() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite"
    }

    /// Pergunta (ou seção) da semana: muda todo domingo; a semana 1 começou em 4/jan/2026.
    static func week(_ b: Book) -> (n: Int, label: String) {
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2026, month: 1, day: 4))!
        let now = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: base, to: now).day ?? 0
        let w = Int(floor(Double(days) / 7))
        let count = b.items.count
        let n = ((w % count) + count) % count + 1
        let start = cal.date(byAdding: .day, value: w * 7, to: base)!
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d MMM"
        let a = f.string(from: start).replacingOccurrences(of: ".", with: "")
        let z = f.string(from: end).replacingOccurrences(of: ".", with: "")
        return (n, "\(a) a \(z)")
    }

    static func hub(_ s: Store) -> (mood: LumiMood, text: String) {
        let ds = s.daysSinceLast
        let lb = s.lastBook.map { Library.book($0).name }
        let any = Library.order.contains { s.hasProgress($0) }
        if !any {
            return (.happy, "\(greet())! Eu sou a Lumi. Trouxe três livros para estudarmos juntos: o **Breve Catecismo**, o **Catecismo Maior** e a **Confissão de Fé**. Toque em um deles!")
        }
        if ds >= 4 {
            return (.sleep, "Zzz… ah, \(greet().lowercased())! Fiquei cuidando dos livros esses \(ds) dias. Vamos voltar ao \(lb ?? "estudo")?")
        }
        if ds == 0 {
            return (.cheer, "Você já estudou hoje! Quer continuar no **\(lb ?? "Breve Catecismo")** ou abrir outro livro?")
        }
        return (.idle, "\(greet())! Da última vez você estava no **\(lb ?? "Breve Catecismo")**. Vamos continuar?")
    }

    static func book(_ b: Book, _ s: Store) -> (mood: LumiMood, text: String) {
        let learned = s.learned(b)
        let mastered = s.mastered(b)
        let wk = week(b)
        let ds = s.daysSinceLast
        var lastU = 0
        if let l = s.last(b.id), l < b.units.count { lastU = l }
        let g = greet()

        let first: String, day: String, wkLine: String
        switch b.id {
        case "maior":
            first = "\(g). O Catecismo Maior aprofunda cada verdade, com respostas mais longas. Vamos devagar, uma lição por vez."
            day = "Bom estudo hoje. " + (mastered > 0 ? "\(mastered) pergunta\(mastered > 1 ? "s" : "") já dominada\(mastered > 1 ? "s" : "")." : "Cada resposta firmada vale a pena.")
            wkLine = "\(g). Pergunta da semana: a \(wk.n). Que tal estudá-la com calma?"
        case "conf":
            let cap = b.item(wk.n).label.components(separatedBy: " · ").first?.lowercased() ?? "capítulo"
            first = "\(g). A Confissão de Fé reúne, em 33 capítulos, a fé que a Igreja confessa. Comece pelo capítulo 1, sobre as Escrituras."
            day = "Que bom ler a Confissão hoje. " + (mastered > 0 ? "\(mastered) \(mastered > 1 ? "seções já bem guardadas" : "seção já bem guardada")." : "Leia com calma; o texto é rico.")
            wkLine = "\(g). A seção da semana é do \(cap). Vamos ler juntos?"
        default:
            first = "\(g)! Vamos aprender o Breve Catecismo juntos? Toque em mim para uma pergunta surpresa."
            day = "Você já estudou hoje! " + (mastered > 0 ? "Já são \(mastered) pergunta\(mastered > 1 ? "s" : "") dominada\(mastered > 1 ? "s" : "")." : "Continue que as chamas vão acender.")
            wkLine = "\(g)! A pergunta da semana é a \(wk.n). Vamos estudar?"
        }

        if learned == 0 { return (.happy, first) }
        if ds >= 4 {
            return (.sleep, "Zzz… ah, \(g.lowercased())! Faz \(ds) dias que não estudamos. Que tal revisar \(b.isConf ? "o capítulo" : "a lição") \(b.unitNum(lastU))?")
        }
        if ds == 0 { return (.happy, day) }
        return (.idle, wkLine)
    }
}

func md(_ s: String) -> AttributedString {
    (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
}
