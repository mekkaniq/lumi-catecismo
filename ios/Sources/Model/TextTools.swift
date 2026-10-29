import Foundation

enum TextTools {
    static let stop: Set<String> = Set(
        "que para como pela pelo pelas pelos nossa nosso nossos nossas todas todos toda todo mesmo sobre entre aquele aqueles aquela aquelas tambem quando porque dele dela delas deles desta deste destas destes mais isto isso seus suas sua seu cada esta este estas estes nesta neste muito sendo assim pois qual quais nele nela nelas neles numa outro outros outra outras ainda aos das dos quanto"
            .split(separator: " ").map(String.init))

    static func words(_ s: String) -> [String] {
        s.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    static func norm(_ w: String) -> String {
        let f = w.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR")).lowercased()
        return String(f.unicodeScalars.filter {
            ($0.value >= 97 && $0.value <= 122) || ($0.value >= 48 && $0.value <= 57) || $0 == "-"
        })
    }

    private static let leadSet = CharacterSet(charactersIn: "“”\"(")
    private static let trailSet = CharacterSet(charactersIn: "“”\").,;:!?")

    static func lead(_ w: String) -> String {
        var out = ""
        for c in w {
            if let u = c.unicodeScalars.first, leadSet.contains(u) { out.append(c) } else { break }
        }
        return out
    }

    static func trail(_ w: String) -> String {
        var out = ""
        for c in w.reversed() {
            if let u = c.unicodeScalars.first, trailSet.contains(u) { out = String(c) + out } else { break }
        }
        return out
    }

    static func bare(_ w: String) -> String {
        var s = w
        s.removeFirst(min(lead(w).count, s.count))
        let t = trail(s)
        s.removeLast(min(t.count, s.count))
        return s
    }

    static func trunc(_ s: String, _ m: Int) -> String {
        guard s.count > m else { return s }
        var cut = String(s.prefix(m))
        if let r = cut.range(of: "\\s+\\S*$", options: .regularExpression) { cut.removeSubrange(r) }
        return cut + "…"
    }

    /// Textos longos (Maior e Confissão): nos jogos usamos o começo, até o fim de uma frase.
    static func gameText(_ a: String) -> (t: String, cut: Bool) {
        let w = words(a)
        if w.count <= 80 { return (a, false) }
        var k = 0
        for i in 44..<min(w.count, 80) {
            if let last = w[i].last, ".;:".contains(last) { k = i + 1; break }
        }
        if k == 0 { k = 60 }
        var t = w[0..<k].joined(separator: " ")
        if let last = t.last, ";:,".contains(last) { t.removeLast() }
        return (t, true)
    }

    static func splitAfterPunct(_ a: String) -> [String] {
        var parts: [String] = []
        var cur = ""
        let chars = Array(a)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace, let last = cur.last, ",;:".contains(last) {
                parts.append(cur)
                cur = ""
                while i < chars.count, chars[i].isWhitespace { i += 1 }
                continue
            }
            cur.append(c)
            i += 1
        }
        if !cur.isEmpty { parts.append(cur) }
        return parts
    }

    private static func slices(_ w: [String], size: Int) -> [String] {
        var out: [String] = []
        var i = 0
        while i < w.count {
            out.append(w[i..<min(i + size, w.count)].joined(separator: " "))
            i += size
        }
        return out
    }

    static func chunksOf(_ a: String) -> [String] {
        var out: [String] = []
        for p in splitAfterPunct(a) {
            let w = words(p)
            if w.count > 8 {
                let k = Int((Double(w.count) / 6).rounded(.up))
                let sz = Int((Double(w.count) / Double(k)).rounded(.up))
                out.append(contentsOf: slices(w, size: sz))
            } else {
                out.append(p)
            }
        }
        var merged: [String] = []
        for c in out {
            if !merged.isEmpty && words(c).count < 2 {
                merged[merged.count - 1] += " " + c
            } else {
                merged.append(c)
            }
        }
        out = merged
        while out.count > 7 {
            var best = 0
            var bl = Int.max
            for i in 0..<(out.count - 1) {
                let l = out[i].count + out[i + 1].count
                if l < bl { bl = l; best = i }
            }
            let joined = out[best] + " " + out[best + 1]
            out.replaceSubrange(best...(best + 1), with: [joined])
        }
        if out.count < 3 {
            let w = words(a)
            let sz = Int((Double(w.count) / 3).rounded(.up))
            out = slices(w, size: max(1, sz))
        }
        return out
    }

    static func candidates(_ item: Item) -> (words: [String], c: [(i: Int, k: String)]) {
        let qs = Set(words(item.q).map { norm($0) })
        let ws = words(gameText(item.a).t)
        var c: [(i: Int, k: String)] = []
        for (i, w) in ws.enumerated() {
            let k = norm(w)
            if k.count >= 4 && !stop.contains(k) && !qs.contains(k) { c.append((i: i, k: k)) }
        }
        return (ws, c)
    }
}
