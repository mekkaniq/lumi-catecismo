import Foundation
import UIKit
import WebKit

/// Ponte para o aula-kit.js (o mesmo código do site), rodando numa WebView invisível:
/// gera o PowerPoint, lê arquivos .pptx e empacota/abre o arquivo da aula (.vvaula).
@MainActor
final class AulaKitBridge: NSObject, WKNavigationDelegate {
    static let shared = AulaKitBridge()

    enum Failure: LocalizedError {
        case missing, message(String)
        var errorDescription: String? {
            switch self {
            case .missing: return "Os arquivos do gerador de slides não estão no app."
            case .message(let m): return m
            }
        }
    }

    private var web: WKWebView?
    private var ready = false
    private var waiting: [CheckedContinuation<Void, Error>] = []

    private func boot() async throws -> WKWebView {
        if let web, ready { return web }
        if web == nil {
            guard let html = Bundle.main.url(forResource: "kit", withExtension: "html", subdirectory: "aula") else { throw Failure.missing }
            let cfg = WKWebViewConfiguration()
            let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 4, height: 4), configuration: cfg)
            w.isHidden = true
            w.navigationDelegate = self
            // Fica numa janela (invisível) para os timers do JavaScript rodarem normalmente.
            if let win = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
                win.addSubview(w)
            }
            web = w
            w.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        }
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            if ready { c.resume() } else { waiting.append(c) }
        }
        return web!
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.ready = true
            let w = self.waiting
            self.waiting = []
            w.forEach { $0.resume() }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            let w = self.waiting
            self.waiting = []
            w.forEach { $0.resume(throwing: error) }
        }
    }

    private func call(_ js: String, _ args: [String: Any]) async throws -> Any? {
        let w = try await boot()
        do {
            return try await w.callAsyncJavaScript(js, arguments: args, contentWorld: .page)
        } catch {
            let msg = (error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String
            throw Failure.message(msg ?? error.localizedDescription)
        }
    }

    private func json(_ a: Aula) throws -> String {
        String(decoding: try JSONEncoder().encode(a), as: UTF8.self)
    }

    private static func decodeMedia(_ any: Any?) -> [String: Data] {
        guard let dict = any as? [String: Any] else { return [:] }
        var out: [String: Data] = [:]
        for (k, v) in dict {
            guard let s = v as? String, let comma = s.firstIndex(of: ",") else { continue }
            if let d = Data(base64Encoded: String(s[s.index(after: comma)...])) { out[k] = d }
        }
        return out
    }

    func pptx(_ a: Aula, media: [String: String]) async throws -> Data {
        let r = try await call("return await AulaKit.toPptx(JSON.parse(aula), media);", ["aula": try json(a), "media": media])
        guard let s = r as? String, let d = Data(base64Encoded: s) else { throw Failure.message("Não consegui gerar o PowerPoint.") }
        return d
    }

    func pack(_ a: Aula, media: [String: String]) async throws -> Data {
        let r = try await call("return await AulaKit.pack(JSON.parse(aula), media);", ["aula": try json(a), "media": media])
        guard let s = r as? String, let d = Data(base64Encoded: s) else { throw Failure.message("Não consegui salvar o arquivo da aula.") }
        return d
    }

    func unpack(_ data: Data) async throws -> (json: String, media: [String: Data]) {
        let r = try await call("const x = await AulaKit.unpack(b64); return { aula: JSON.stringify(x.aula), media: x.media };", ["b64": data.base64EncodedString()])
        guard let d = r as? [String: Any], let j = d["aula"] as? String else { throw Failure.message("Este arquivo não é uma aula do Verso Vivo.") }
        return (j, Self.decodeMedia(d["media"]))
    }

    func parsePptx(_ data: Data) async throws -> (json: String, media: [String: Data]) {
        let r = try await call("const x = await AulaKit.parsePptx(b64); return { slides: JSON.stringify(AulaKit.slidesFromPptx(x)), media: x.media };", ["b64": data.base64EncodedString()])
        guard let d = r as? [String: Any], let j = d["slides"] as? String else { throw Failure.message("Não consegui ler este PowerPoint.") }
        return (j, Self.decodeMedia(d["media"]))
    }
}
