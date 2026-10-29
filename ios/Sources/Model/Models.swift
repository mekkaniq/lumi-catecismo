import Foundation

struct Item: Codable, Identifiable, Hashable {
    let n: Int
    let q: String
    let a: String
    let r: String
    let label: String
    let ch: Int?
    let sec: Int?
    var id: Int { n }
}

struct Unit: Codable, Hashable {
    let t: String
    let a: Int
    let b: Int
    let ch: Int?
}

struct Book: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let full: String
    let tag: String
    let sub: String
    let items: [Item]
    let units: [Unit]

    var isConf: Bool { id == "conf" }
    var itemWord: String { isConf ? "Seção" : "Pergunta" }
    var unitWord: String { isConf ? "Capítulo" : "Lição" }
    var all: [Int] { Array(1...items.count) }

    func item(_ n: Int) -> Item { items[n - 1] }
    func unitNum(_ u: Int) -> Int { isConf ? (units[u].ch ?? u + 1) : u + 1 }
    func nums(_ u: Int) -> [Int] { u < 0 ? all : Array(units[u].a...units[u].b) }
    func unitOf(_ n: Int) -> Int { units.firstIndex(where: { n >= $0.a && n <= $0.b }) ?? 0 }

    func unitRange(_ i: Int) -> String {
        let u = units[i]
        if isConf {
            let c = u.b - u.a + 1
            return "\(c) \(c == 1 ? "seção" : "seções")"
        }
        return "Perguntas \(u.a)–\(u.b)"
    }

    var countsLine: String {
        isConf ? "33 capítulos · \(items.count) seções" : "\(items.count) perguntas · \(units.count) lições"
    }
}

struct TextPiece: Codable {
    let t: String
    let ref: String
    let list: [String]?
    let after: String?
    let body: String?
}

enum Library {
    static let order = ["breve", "maior", "conf"]
    static let books: [Book] = load("books")
    static let texts: [String: TextPiece] = load("texts")

    static func book(_ id: String) -> Book {
        books.first(where: { $0.id == id }) ?? books[0]
    }

    private static func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Dados ausentes: \(name)")
        }
        return value
    }
}
