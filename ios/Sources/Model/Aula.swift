import Foundation
import SwiftUI

/// Tipos de slide de uma aula (os mesmos do site e do PowerPoint: aula/aula-kit.js).
enum SlideKind: String, Codable, CaseIterable, Identifiable {
    case titulo, catecismo, biblia, topicos, imagem, discussao, quiz, pagina
    var id: String { rawValue }

    var name: String {
        switch self {
        case .titulo: return "Título"
        case .catecismo: return "Catecismo"
        case .biblia: return "Texto bíblico"
        case .topicos: return "Tópicos"
        case .imagem: return "Imagem"
        case .discussao: return "Para conversar"
        case .quiz: return "Quiz"
        case .pagina: return "Página importada"
        }
    }

    var icon: String {
        switch self {
        case .titulo: return "textformat.size"
        case .catecismo: return "questionmark.bubble.fill"
        case .biblia: return "book.fill"
        case .topicos: return "list.bullet"
        case .imagem: return "photo.fill"
        case .discussao: return "person.2.wave.2.fill"
        case .quiz: return "checklist"
        case .pagina: return "doc.richtext.fill"
        }
    }

    /// Tipos que o professor cria pelo botão "+" (página importada vem de PDF/PowerPoint).
    static let creatable: [SlideKind] = [.titulo, .catecismo, .biblia, .topicos, .imagem, .discussao, .quiz]
    var hasReveal: Bool { self == .catecismo || self == .quiz }
}

struct AulaSlide: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var kind: SlideKind
    var title = ""
    var text = ""
    var items: [String] = []
    var ref = ""
    var version = ""
    var label = ""
    var q = ""
    var a = ""
    var r = ""
    var book: String? = nil
    var n: Int? = nil
    var img: String? = nil
    var ok = 0
    var notes = ""

    init(kind: SlideKind) {
        self.kind = kind
        switch kind {
        case .discussao: text = "Para conversar"
        case .quiz: items = ["", "", "", ""]
        case .topicos: items = ["", ""]
        default: break
        }
    }

    enum CodingKeys: String, CodingKey { case id, kind, title, text, items, ref, version, label, q, a, r, book, n, img, ok, notes }

    /// Aceita arquivos com campos faltando (ex.: slides vindos de um PowerPoint importado).
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        kind = (try? c.decode(SlideKind.self, forKey: .kind)) ?? .topicos
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        text = (try? c.decode(String.self, forKey: .text)) ?? ""
        items = (try? c.decode([String].self, forKey: .items)) ?? []
        ref = (try? c.decode(String.self, forKey: .ref)) ?? ""
        version = (try? c.decode(String.self, forKey: .version)) ?? ""
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        q = (try? c.decode(String.self, forKey: .q)) ?? ""
        a = (try? c.decode(String.self, forKey: .a)) ?? ""
        r = (try? c.decode(String.self, forKey: .r)) ?? ""
        book = try? c.decode(String.self, forKey: .book)
        n = try? c.decode(Int.self, forKey: .n)
        img = try? c.decode(String.self, forKey: .img)
        ok = (try? c.decode(Int.self, forKey: .ok)) ?? 0
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
    }

    /// Resumo de uma linha para a lista de slides.
    var summary: String {
        switch kind {
        case .catecismo: return q.isEmpty ? "Escolha uma pergunta" : q
        case .biblia: return ref.isEmpty ? (text.isEmpty ? "Sem texto" : text) : ref
        case .imagem: return title.isEmpty ? (img == nil ? "Sem imagem" : "Imagem") : title
        case .pagina: return title.isEmpty ? "Página" : title
        case .topicos: return title.isEmpty ? items.filter { !$0.isEmpty }.joined(separator: " · ") : title
        default: return title.isEmpty ? "Sem título" : title
        }
    }
}

struct Aula: Codable, Identifiable, Hashable {
    var v = 1
    var id: String = UUID().uuidString
    var title = "Nova aula"
    var theme = "verde"
    var updated: Double = Date().timeIntervalSince1970
    var slides: [AulaSlide] = []

    init(title: String = "Nova aula", theme: String = "verde", slides: [AulaSlide] = []) {
        self.title = title
        self.theme = theme
        self.slides = slides
    }

    enum CodingKeys: String, CodingKey { case v, id, title, theme, updated, slides }

    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        v = (try? c.decode(Int.self, forKey: .v)) ?? 1
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? "Aula"
        theme = (try? c.decode(String.self, forKey: .theme)) ?? "verde"
        updated = (try? c.decode(Double.self, forKey: .updated)) ?? Date().timeIntervalSince1970
        slides = (try? c.decode([AulaSlide].self, forKey: .slides)) ?? []
    }

    /// Cada slide com resposta escondida rende dois quadros: pergunta e resposta.
    var frames: [Frame] {
        var out: [Frame] = []
        for (i, s) in slides.enumerated() {
            out.append(Frame(i: i, step: 0))
            if s.kind.hasReveal { out.append(Frame(i: i, step: 1)) }
        }
        return out
    }

    /// Imagens usadas pelos slides.
    var mediaNames: Set<String> { Set(slides.compactMap { $0.img }) }

    var updatedText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d 'de' MMM, HH:mm"
        return f.string(from: Date(timeIntervalSince1970: updated))
    }
}

struct Frame: Hashable {
    let i: Int
    let step: Int
}

/// Temas dos slides (iguais aos do site e do PowerPoint).
struct SlideTheme {
    let id: String
    let name: String
    let bg: UInt32, bg2: UInt32, fg: UInt32, muted: UInt32, accent: UInt32, card: UInt32, ok: UInt32

    static let all: [SlideTheme] = [
        SlideTheme(id: "verde", name: "Verde", bg: 0x0E170A, bg2: 0x3D5A2A, fg: 0xFBF1D8, muted: 0xCFC09A, accent: 0xF0CD7E, card: 0x1F2C16, ok: 0x9FD08A),
        SlideTheme(id: "vinho", name: "Vinho", bg: 0x1C0A0C, bg2: 0x7A2F38, fg: 0xFBF1D8, muted: 0xE3C7B8, accent: 0xF0CD7E, card: 0x2E1316, ok: 0x9FD08A),
        SlideTheme(id: "azul", name: "Azul", bg: 0x071720, bg2: 0x245A74, fg: 0xFBF1D8, muted: 0xBFD6DE, accent: 0xF0CD7E, card: 0x10293A, ok: 0x9FD08A),
        SlideTheme(id: "claro", name: "Pergaminho", bg: 0xF7EDD3, bg2: 0xEAD9AE, fg: 0x2A1D0C, muted: 0x6D5C3B, accent: 0x9A6B12, card: 0xFFFAEC, ok: 0x2F7D4A),
    ]

    static func of(_ id: String) -> SlideTheme { all.first { $0.id == id } ?? all[0] }
}

enum SlideFit {
    /// Mesmo cálculo do aula-kit.js: tamanho de letra (pt num slide de 960 pt de largura) conforme o tamanho do texto.
    static func size(_ text: String, _ big: CGFloat, _ small: CGFloat, _ longAt: CGFloat) -> CGFloat {
        let n = CGFloat(text.count)
        if n <= longAt * 0.35 { return big }
        if n >= longAt { return small }
        let t = (n - longAt * 0.35) / (longAt * 0.65)
        return (big - (big - small) * t).rounded()
    }
}

extension Aula {
    /// Aula de exemplo, para quem abre a área pela primeira vez.
    static func sample() -> Aula {
        let b = Library.book("breve")
        let x = b.item(1)
        var t = AulaSlide(kind: .titulo)
        t.title = "Para que fomos criados?"
        t.text = "Escola Dominical"
        t.items = ["Nome do professor"]
        var c = AulaSlide(kind: .catecismo)
        c.book = "breve"; c.n = 1
        c.label = "\(b.name) · \(x.label)"
        c.q = x.q; c.a = x.a; c.r = x.r
        c.notes = "Pergunte à turma antes de revelar a resposta."
        var bi = AulaSlide(kind: .biblia)
        bi.ref = "1 Coríntios 10.31"
        bi.text = "Cole aqui o texto da versão da Bíblia que a igreja usa."
        var tp = AulaSlide(kind: .topicos)
        tp.title = "Três verdades"
        tp.items = ["Deus é o centro de tudo", "A glória de Deus é o nosso bem", "Gozar a Deus é para sempre"]
        var d = AulaSlide(kind: .discussao)
        d.title = "Em que parte da sua semana é mais difícil viver para a glória de Deus?"
        var qz = AulaSlide(kind: .quiz)
        qz.title = "Qual é o fim principal do homem?"
        qz.items = ["Ser feliz", "Glorificar a Deus e gozá-lo para sempre", "Fazer boas obras", "Ir à igreja"]
        qz.ok = 1
        return Aula(title: "Exemplo · O fim principal do homem", theme: "verde", slides: [t, c, bi, tp, d, qz])
    }
}
