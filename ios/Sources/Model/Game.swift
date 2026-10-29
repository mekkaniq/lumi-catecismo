import Foundation
import SwiftUI

enum LumiMood: String {
    case idle, happy, cheer, meh, sad, think, sleep
}

enum PlayMode: String {
    case quiz, complete, build, mix

    var title: String {
        switch self {
        case .quiz: return "Quiz"
        case .complete: return "Completar"
        case .build: return "Montar"
        case .mix: return "Desafio"
        }
    }
}

enum BackTarget { case book, unit }

struct BankItem: Identifiable {
    let id = UUID()
    let w: String
    var used = false
}

struct Tone {
    let praise: [String]
    let meh: String
    let mehOk: String
    let sad: String

    static func of(_ id: String) -> Tone {
        switch id {
        case "maior":
            return Tone(praise: ["Correto.", "Muito bem.", "Exato.", "Bom estudo.", "Resposta firme."], meh: "Quase.", mehOk: "Quase perfeito.", sad: "Vale revisar")
        case "conf":
            return Tone(praise: ["Correto.", "Fiel ao texto.", "Muito bem.", "Exato.", "Assim confessamos."], meh: "Quase.", mehOk: "Quase perfeito.", sad: "Vale reler o texto")
        default:
            return Tone(praise: ["Muito bem!", "Isso mesmo!", "Correto!", "Boa memória!", "Excelente!"], meh: "Quase!", mehOk: "Quase perfeito!", sad: "Vamos revisar")
        }
    }
}

@MainActor
final class Game: ObservableObject {
    let book: Book
    let pool: [Int]
    let mode: PlayMode
    let back: BackTarget
    private let store: Store
    let tone: Tone

    var items: [(n: Int, mode: PlayMode)] = []

    @Published var i = 0
    @Published var ok = 0
    @Published var done = false
    @Published var miss = 0
    @Published var correct = false
    @Published var mood: LumiMood? = nil
    @Published var live: LumiMood = .think
    @Published var finished = false

    // quiz
    @Published var opts: [Int] = []
    @Published var chosen: Int? = nil
    @Published var excerpt = ""
    // completar
    @Published var words: [String] = []
    @Published var cut = false
    @Published var blanks: [Int] = []
    @Published var filled = 0
    @Published var bank: [BankItem] = []
    @Published var wrongChip: UUID? = nil
    // montar
    @Published var chunks: [String] = []
    @Published var order: [Int] = []
    @Published var placed: [Int] = []
    @Published var wrongChunk: Int? = nil

    private var reactTask: Task<Void, Never>?

    init(book: Book, pool: [Int], mode: PlayMode, back: BackTarget, store: Store) {
        self.book = book
        self.pool = pool
        self.mode = mode
        self.back = back
        self.store = store
        self.tone = Tone.of(book.id)
        let sel = Array(pool.shuffled().prefix(min(8, pool.count)))
        let modes: [PlayMode] = [.quiz, .complete, .build]
        items = sel.map { (n: $0, mode: mode == .mix ? modes.randomElement()! : mode) }
        setup()
    }

    var current: (n: Int, mode: PlayMode) { items[i] }
    var item: Item { book.item(items[i].n) }
    var isConfQuiz: Bool { book.isConf && items[i].mode == .quiz }

    func shown(_ m: LumiMood) -> LumiMood { (book.isConf && m == .cheer) ? .happy : m }

    // MARK: preparo de cada pergunta
    private func setup() {
        let itm = items[i]
        let n = itm.n
        let x = book.item(n)
        done = false
        miss = 0
        correct = false
        mood = nil
        chosen = nil
        live = .think
        wrongChip = nil
        wrongChunk = nil

        switch itm.mode {
        case .complete:
            let gt = TextTools.gameText(x.a)
            let cand = TextTools.candidates(x)
            let ws = cand.words
            let k = min(cand.c.count, ws.count < 15 ? 2 : ws.count < 35 ? 3 : 4)
            if k < 1 {
                items[i].mode = .quiz
                setup()
                return
            }
            var seen = Set<String>()
            var picked: [(i: Int, k: String)] = []
            for o in cand.c.shuffled() {
                if picked.count >= k { break }
                if !seen.contains(o.k) { seen.insert(o.k); picked.append(o) }
            }
            picked.sort { $0.i < $1.i }
            var others: [String] = []
            for m in book.all.filter({ $0 != n }).shuffled().prefix(6) {
                let cc = TextTools.candidates(book.item(m))
                for o in cc.c { others.append(TextTools.bare(cc.words[o.i])) }
            }
            var distract: [String] = []
            for w in others.shuffled() {
                if distract.count >= 2 { break }
                let nw = TextTools.norm(w)
                if !seen.contains(nw) && !distract.contains(where: { TextTools.norm($0) == nw }) {
                    distract.append(w)
                }
            }
            words = ws
            cut = gt.cut
            blanks = picked.map { $0.i }
            filled = 0
            let target = picked.map { TextTools.bare(ws[$0.i]) } + distract
            bank = target.shuffled().map { BankItem(w: $0) }

        case .build:
            let gt = TextTools.gameText(x.a)
            let ch = TextTools.chunksOf(gt.t)
            chunks = ch
            cut = gt.cut
            var ord = Array(0..<ch.count).shuffled()
            if ch.count > 1 && ord == Array(0..<ch.count) { ord.reverse() }
            order = ord
            placed = []

        default:
            if book.isConf {
                let chs = book.units.compactMap { $0.ch }.filter { $0 != x.ch }
                opts = ([x.ch ?? 0] + Array(chs.shuffled().prefix(3))).shuffled()
                excerpt = TextTools.words(TextTools.gameText(x.a).t).prefix(34).joined(separator: " ")
            } else {
                let list = pool.filter { $0 != n }
                let source = list.count >= 3 ? list : book.all.filter { $0 != n }
                let wrong = Array(source.shuffled().prefix(3))
                opts = ([n] + wrong).shuffled()
            }
        }
    }

    // MARK: ações
    func pickQuiz(_ m: Int) {
        guard !done else { return }
        let n = items[i].n
        chosen = m
        let ok = book.isConf ? (m == book.item(n).ch) : (m == n)
        if !ok { miss = 1 }
        answered(ok)
    }

    func pickChip(_ k: Int) {
        guard !done, k < bank.count, !bank[k].used else { return }
        let expected = TextTools.norm(words[blanks[filled]])
        if TextTools.norm(bank[k].w) == expected {
            bank[k].used = true
            filled += 1
            if filled >= blanks.count { answered(miss <= 1); return }
            react(.happy, ms: 700)
            Haptics.tap()
        } else {
            miss += 1
            let id = bank[k].id
            wrongChip = id
            Haptics.miss()
            react(miss >= 2 ? .sad : .meh, ms: 900)
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 450_000_000)
                if self?.wrongChip == id { self?.wrongChip = nil }
            }
        }
    }

    func pickChunk(_ k: Int) {
        guard !done, placed.count < chunks.count else { return }
        let expected = chunks[placed.count]
        if chunks[k] == expected {
            placed.append(k)
            if placed.count == chunks.count { answered(miss <= 1); return }
            react(.happy, ms: 700)
            Haptics.tap()
        } else {
            miss += 1
            wrongChunk = k
            Haptics.miss()
            react(miss >= 2 ? .sad : .meh, ms: 900)
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 450_000_000)
                if self?.wrongChunk == k { self?.wrongChunk = nil }
            }
        }
    }

    private func answered(_ ok: Bool) {
        let n = items[i].n
        done = true
        correct = ok
        let m: LumiMood = miss == 0 ? .cheer : miss == 1 ? .meh : .sad
        mood = m
        live = shown(m)
        reactTask?.cancel()
        if ok {
            self.ok += 1
            store.bump(book.id, n)
        }
        store.markDay(book.id)
        if m == .cheer { Haptics.success() } else if m == .meh { Haptics.tap() } else { Haptics.miss() }
    }

    /// Só para as capturas de tela do CI.
    func debugAnswer(right: Bool) {
        switch items[i].mode {
        case .quiz:
            if book.isConf { pickQuiz(right ? (item.ch ?? 0) : (opts.first(where: { $0 != item.ch }) ?? 0)) }
            else { pickQuiz(right ? items[i].n : (opts.first(where: { $0 != items[i].n }) ?? 0)) }
        default:
            miss = right ? 0 : 2
            answered(right)
        }
    }

    func next() {
        i += 1
        if i >= items.count {
            finished = true
            return
        }
        setup()
    }

    private func react(_ m: LumiMood, ms: Int) {
        live = shown(m)
        reactTask?.cancel()
        reactTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
            if Task.isCancelled { return }
            if let s = self, !s.done { s.live = .think }
        }
    }
}
