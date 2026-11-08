import Foundation
import SwiftUI
import UIKit
import PDFKit

/// Guarda as aulas no aparelho: Documentos/Aulas/<id>/aula.json + media/.
@MainActor
final class AulaStore: ObservableObject {
    @Published private(set) var aulas: [Aula] = []

    private let fm = FileManager.default
    private var root: URL {
        let d = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Aulas", isDirectory: true)
        try? fm.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    init() { reload() }

    func dir(_ id: String) -> URL { root.appendingPathComponent(id, isDirectory: true) }
    func mediaDir(_ id: String) -> URL {
        let d = dir(id).appendingPathComponent("media", isDirectory: true)
        try? fm.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    func mediaURL(_ aulaID: String, _ name: String) -> URL { mediaDir(aulaID).appendingPathComponent(name) }

    func reload() {
        let ids = (try? fm.contentsOfDirectory(atPath: root.path)) ?? []
        aulas = ids.compactMap { id in
            guard let data = try? Data(contentsOf: dir(id).appendingPathComponent("aula.json")) else { return nil }
            return try? JSONDecoder().decode(Aula.self, from: data)
        }
        .sorted { $0.updated > $1.updated }
    }

    func aula(_ id: String) -> Aula? { aulas.first { $0.id == id } }

    @discardableResult
    func save(_ a: Aula, touch: Bool = true) -> Aula {
        var a = a
        if touch { a.updated = Date().timeIntervalSince1970 }
        try? fm.createDirectory(at: dir(a.id), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(a) {
            try? data.write(to: dir(a.id).appendingPathComponent("aula.json"), options: .atomic)
        }
        if let i = aulas.firstIndex(where: { $0.id == a.id }) { aulas[i] = a } else { aulas.insert(a, at: 0) }
        aulas.sort { $0.updated > $1.updated }
        cleanMedia(a)
        return a
    }

    func create(_ a: Aula = Aula(title: "Nova aula", slides: [AulaSlide(kind: .titulo)])) -> Aula {
        var a = a
        if a.slides.isEmpty { a.slides = [AulaSlide(kind: .titulo)] }
        if a.slides[0].kind == .titulo && a.slides[0].title.isEmpty { a.slides[0].title = a.title }
        return save(a)
    }

    func delete(_ id: String) {
        try? fm.removeItem(at: dir(id))
        aulas.removeAll { $0.id == id }
    }

    func duplicate(_ id: String) -> Aula? {
        guard var a = aula(id) else { return nil }
        let old = a.id
        a.id = UUID().uuidString
        a.title += " (cópia)"
        try? fm.createDirectory(at: dir(a.id), withIntermediateDirectories: true)
        try? fm.copyItem(at: mediaDir(old), to: dir(a.id).appendingPathComponent("media-tmp"))
        try? fm.removeItem(at: mediaDir(a.id))
        try? fm.moveItem(at: dir(a.id).appendingPathComponent("media-tmp"), to: dir(a.id).appendingPathComponent("media"))
        return save(a)
    }

    /// Apaga imagens que nenhum slide usa mais.
    private func cleanMedia(_ a: Aula) {
        let used = a.mediaNames
        let files = (try? fm.contentsOfDirectory(atPath: mediaDir(a.id).path)) ?? []
        for f in files where !used.contains(f) { try? fm.removeItem(at: mediaURL(a.id, f)) }
    }

    // MARK: imagens

    /// Guarda uma imagem (reduzida para no máximo 1920 px) e devolve o nome do arquivo.
    func addImage(_ img: UIImage, to aulaID: String, maxSide: CGFloat = 1920) -> String? {
        let im = img.resized(maxSide: maxSide)
        guard let data = im.jpegData(compressionQuality: 0.82) else { return nil }
        let name = UUID().uuidString.prefix(12).lowercased() + ".jpg"
        do { try data.write(to: mediaURL(aulaID, name)); return name } catch { return nil }
    }

    func addMedia(_ data: Data, name: String, to aulaID: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        let safe = UUID().uuidString.prefix(12).lowercased() + "." + (["png", "gif", "jpg", "jpeg"].contains(ext) ? ext : "jpg")
        try? data.write(to: mediaURL(aulaID, safe))
        return safe
    }

    func image(_ aulaID: String, _ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(contentsOfFile: mediaURL(aulaID, name).path)
    }

    /// Imagens da aula como data URL (para o PowerPoint e o arquivo da aula).
    func mediaDataURLs(_ a: Aula) -> [String: String] {
        var out: [String: String] = [:]
        for n in a.mediaNames {
            guard let d = try? Data(contentsOf: mediaURL(a.id, n)) else { continue }
            let mime = n.hasSuffix(".png") ? "image/png" : n.hasSuffix(".gif") ? "image/gif" : "image/jpeg"
            out[n] = "data:\(mime);base64," + d.base64EncodedString()
        }
        return out
    }

    // MARK: importar

    /// Páginas de um PDF viram slides "página importada".
    func pdfSlides(_ url: URL, into aulaID: String) -> [AulaSlide] {
        guard let doc = PDFDocument(url: url) else { return [] }
        var out: [AulaSlide] = []
        for k in 0..<min(doc.pageCount, 120) {
            guard let page = doc.page(at: k) else { continue }
            let box = page.bounds(for: .mediaBox)
            let scale = 1920 / max(box.width, box.height)
            let size = CGSize(width: box.width * scale, height: box.height * scale)
            let img = page.thumbnail(of: size, for: .mediaBox)
            if let name = addImage(img, to: aulaID) {
                var s = AulaSlide(kind: .pagina)
                s.img = name
                s.title = "Página \(k + 1)"
                out.append(s)
            }
        }
        return out
    }

    /// Lê um arquivo de aula (.vvaula) e guarda como aula nova.
    func importPackage(_ data: Data) async throws -> Aula {
        let r = try await AulaKitBridge.shared.unpack(data)
        var a = try JSONDecoder().decode(Aula.self, from: Data(r.json.utf8))
        if aula(a.id) != nil { a.id = UUID().uuidString }
        for (name, d) in r.media { try? d.write(to: mediaURL(a.id, name)) }
        return save(a, touch: true)
    }

    /// Lê um PowerPoint: o texto de cada slide vira tópicos, e a maior imagem vem junto.
    func pptxSlides(_ data: Data, into aulaID: String) async throws -> [AulaSlide] {
        let r = try await AulaKitBridge.shared.parsePptx(data)
        var slides = (try? JSONDecoder().decode([AulaSlide].self, from: Data(r.json.utf8))) ?? []
        for i in slides.indices { slides[i].id = UUID().uuidString }
        var rename: [String: String] = [:]
        for (name, d) in r.media { rename[name] = addMedia(d, name: name, to: aulaID) }
        for i in slides.indices { if let n = slides[i].img { slides[i].img = rename[n] } }
        return slides
    }

    // MARK: exportar

    private func tempURL(_ a: Aula, ext: String) -> URL {
        let safe = a.title.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-").trimmingCharacters(in: .whitespaces)
        let d = fm.temporaryDirectory.appendingPathComponent("export-" + UUID().uuidString.prefix(6), isDirectory: true)
        try? fm.createDirectory(at: d, withIntermediateDirectories: true)
        return d.appendingPathComponent((safe.isEmpty ? "Aula" : safe) + "." + ext)
    }

    func exportPackage(_ a: Aula) async throws -> URL {
        let data = try await AulaKitBridge.shared.pack(a, media: mediaDataURLs(a))
        let url = tempURL(a, ext: "vvaula")
        try data.write(to: url)
        return url
    }

    func exportPptx(_ a: Aula) async throws -> URL {
        let data = try await AulaKitBridge.shared.pptx(a, media: mediaDataURLs(a))
        let url = tempURL(a, ext: "pptx")
        try data.write(to: url)
        return url
    }

    func exportPDF(_ a: Aula) -> URL? {
        let url = tempURL(a, ext: "pdf")
        let size = CGSize(width: 1280, height: 720)
        let images = Dictionary(uniqueKeysWithValues: a.mediaNames.compactMap { n in image(a.id, n).map { (n, $0) } })
        let frames = a.frames
        let fmt = UIGraphicsPDFRendererFormat()
        fmt.documentInfo = [kCGPDFContextTitle as String: a.title, kCGPDFContextCreator as String: "Verso Vivo Catecismos"]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size), format: fmt)
        do {
            try renderer.writePDF(to: url) { ctx in
                for (k, f) in frames.enumerated() {
                    ctx.beginPage()
                    let view = SlideView(aula: a, frame: f, index: k, total: frames.count, images: images)
                        .frame(width: size.width, height: size.height)
                    let r = ImageRenderer(content: view)
                    r.proposedSize = ProposedViewSize(size)
                    let cg = ctx.cgContext
                    r.render { _, draw in
                        cg.saveGState()
                        cg.translateBy(x: 0, y: size.height)
                        cg.scaleBy(x: 1, y: -1)
                        draw(cg)
                        cg.restoreGState()
                    }
                }
            }
            return url
        } catch { return nil }
    }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let m = max(size.width, size.height)
        guard m > maxSide else { return self }
        let k = maxSide / m
        let s = CGSize(width: (size.width * k).rounded(), height: (size.height * k).rounded())
        let f = UIGraphicsImageRendererFormat.default()
        f.scale = 1
        return UIGraphicsImageRenderer(size: s, format: f).image { _ in draw(in: CGRect(origin: .zero, size: s)) }
    }
}
