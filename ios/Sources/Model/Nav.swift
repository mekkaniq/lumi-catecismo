import Foundation
import SwiftUI

enum Route: Hashable {
    case book(String)
    case unit(String, Int)
    case study(String, Int, Int)
    case game
    case result
    case classroom(String, Int, Int)
    case text(String)
}

@MainActor
final class Nav: ObservableObject {
    @Published var path: [Route] = []
    @Published var game: Game?

    func push(_ r: Route) { path.append(r) }
    func pop() { if !path.isEmpty { path.removeLast() } }

    func startGame(_ book: Book, pool: [Int], mode: PlayMode, back: BackTarget, store: Store) {
        game = Game(book: book, pool: pool, mode: mode, back: back, store: store)
        path.append(.game)
    }

    func finishGame() {
        if path.last == .game { path.removeLast() }
        path.append(.result)
    }

    func again(store: Store) {
        guard let g = game else { return }
        game = Game(book: g.book, pool: g.pool, mode: g.mode, back: g.back, store: store)
        if path.last == .result { path.removeLast() }
        path.append(.game)
    }

    func popToBook() {
        while let l = path.last {
            if case .book = l { break }
            path.removeLast()
        }
    }

    func studyFromResult(_ g: Game) {
        let u = g.pool.first.map { g.book.unitOf($0) } ?? 0
        if path.last == .result { path.removeLast() }
        path.append(.study(g.book.id, u, 0))
    }

    /// Argumentos de execução usados só pelo CI para tirar capturas de cada tela.
    func applyLaunchArguments(_ store: Store) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        let shot = a[i + 1]
        let id = a.firstIndex(of: "-book").flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil } ?? "breve"
        let b = Library.book(id)
        if a.contains("-demo") { store.seedDemo() }
        let answer = a.firstIndex(of: "-answer").flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil }

        switch shot {
        case "book": path = [.book(id)]
        case "unit": path = [.book(id), .unit(id, 0)]
        case "study": path = [.book(id), .unit(id, 0), .study(id, 0, 0)]
        case "quiz", "complete", "build", "mix":
            path = [.book(id), .unit(id, 0)]
            game = Game(book: b, pool: b.nums(0), mode: PlayMode(rawValue: shot) ?? .quiz, back: .unit, store: store)
            path.append(.game)
            if let ans = answer { game?.debugAnswer(right: ans == "right") }
        case "result":
            path = [.book(id), .unit(id, 0)]
            let g = Game(book: b, pool: b.nums(0), mode: .mix, back: .unit, store: store)
            g.ok = 7
            game = g
            path.append(.result)
        case "lastq":
            path = [.book(id), .unit(id, 0)]
            let g = Game(book: b, pool: b.nums(0), mode: .quiz, back: .unit, store: store)
            g.debugJumpToLast()
            g.debugAnswer(right: true)
            game = g
            path.append(.game)
            Task { @MainActor [weak g] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                g?.next()
            }
        case "class": path = [.book(id), .classroom(id, 0, 0)]
        case "text": path = [.text("mand")]
        default: break
        }
    }
}
