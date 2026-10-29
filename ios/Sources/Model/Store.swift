import Foundation
import SwiftUI

struct BookProgress: Codable {
    var m: [String: Int] = [:]
    var last: Int? = nil
}

struct Persisted: Codable {
    var books: [String: BookProgress] = [:]
    var days: Set<String> = []
    var lastDay: String? = nil
    var lastBook: String? = nil
    var scoreA = 0
    var scoreB = 0
    var scoreOn = false
    var fs = 0
}

@MainActor
final class Store: ObservableObject {
    @Published private(set) var d = Persisted()
    private let key = "lumi-catecismos-ios-v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let v = try? JSONDecoder().decode(Persisted.self, from: data) {
            d = v
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(d) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: progresso
    func stars(_ book: String, _ n: Int) -> Int { d.books[book]?.m[String(n)] ?? 0 }

    func bump(_ book: String, _ n: Int) {
        var p = d.books[book] ?? BookProgress()
        p.m[String(n)] = min(3, (p.m[String(n)] ?? 0) + 1)
        d.books[book] = p
        save()
    }

    func last(_ book: String) -> Int? { d.books[book]?.last }

    func setLast(_ book: String, _ unit: Int) {
        var p = d.books[book] ?? BookProgress()
        p.last = unit
        d.books[book] = p
        d.lastBook = book
        save()
    }

    func setLastBook(_ id: String) { d.lastBook = id; save() }
    var lastBook: String? { d.lastBook }

    func markDay(_ book: String) {
        d.days.insert(Store.today())
        d.lastDay = Store.today()
        d.lastBook = book
        save()
    }

    func hasProgress(_ book: String) -> Bool { !(d.books[book]?.m.isEmpty ?? true) }

    func pct(_ b: Book, _ list: [Int]) -> Int {
        guard !list.isEmpty else { return 0 }
        let s = list.reduce(0) { $0 + stars(b.id, $1) }
        return Int((Double(s) / Double(list.count * 3) * 100).rounded())
    }
    func pctOf(_ b: Book) -> Int { pct(b, b.all) }
    func learned(_ b: Book) -> Int { b.all.filter { stars(b.id, $0) > 0 }.count }
    func mastered(_ b: Book) -> Int { b.all.filter { stars(b.id, $0) >= 3 }.count }
    var daysCount: Int { d.days.count }

    var daysSinceLast: Int {
        guard let s = d.lastDay, let date = Store.parse(s) else { return 9999 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
    }

    // MARK: placar da classe
    func addScore(team: Int, delta: Int) {
        if team == 0 { d.scoreA = max(0, d.scoreA + delta) } else { d.scoreB = max(0, d.scoreB + delta) }
        save()
    }
    func zeroScore() { d.scoreA = 0; d.scoreB = 0; save() }
    func toggleScore() { d.scoreOn.toggle(); save() }

    // MARK: tamanho da letra
    func cycleFont() { d.fs = (d.fs + 1) % 3; save() }
    func setFont(_ v: Int) { d.fs = min(max(v, 0), 2); save() }

    // MARK: apagar progresso (Ajustes)
    func resetProgress() {
        d.books = [:]
        d.days = []
        d.lastDay = nil
        d.lastBook = nil
        d.scoreA = 0
        d.scoreB = 0
        save()
    }

    // MARK: demonstração (usada só nas capturas de tela do CI)
    func seedDemo() {
        for (id, upto) in [("breve", 40), ("maior", 12), ("conf", 9)] {
            var p = BookProgress()
            for n in 1...upto { p.m[String(n)] = n % 4 == 0 ? 1 : n % 3 == 0 ? 2 : 3 }
            p.last = 2
            d.books[id] = p
        }
        d.days = [Store.today(), "2026-10-20", "2026-10-21"]
        d.lastDay = Store.today()
        d.lastBook = "breve"
    }

    // MARK: datas
    static func today() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    static func parse(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}
