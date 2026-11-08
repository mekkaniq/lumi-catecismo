import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

extension UTType {
    static let vvaula = UTType(exportedAs: "br.com.editoraversovivo.aula", conformingTo: .data)
    static let pptx = UTType(filenameExtension: "pptx") ?? .data
}

/// Abre arquivos vindos de fora (Arquivos, WhatsApp, e-mail) e cria aulas a partir deles.
@MainActor
enum AulaImport {
    static func newAula(from url: URL, store aulas: AulaStore) async throws -> Aula {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let ext = url.pathExtension.lowercased()
        let name = url.deletingPathExtension().lastPathComponent
        if ext == "vvaula" || ext == "zip" {
            return try await aulas.importPackage(try Data(contentsOf: url))
        }
        var a = aulas.create(Aula(title: name, slides: [titleSlide(name)]))
        if ext == "pdf" {
            a.slides += aulas.pdfSlides(url, into: a.id)
        } else if ext == "pptx" {
            a.slides += try await aulas.pptxSlides(try Data(contentsOf: url), into: a.id)
        } else if let img = UIImage(contentsOfFile: url.path), let n = aulas.addImage(img, to: a.id) {
            var s = AulaSlide(kind: .imagem)
            s.img = n
            a.slides.append(s)
        }
        return aulas.save(a)
    }

    static func titleSlide(_ t: String) -> AulaSlide {
        var s = AulaSlide(kind: .titulo)
        s.title = t
        return s
    }

    /// Slides extras para uma aula que já existe.
    static func slides(from url: URL, into aulaID: String, store aulas: AulaStore) async throws -> [AulaSlide] {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        switch url.pathExtension.lowercased() {
        case "pdf": return aulas.pdfSlides(url, into: aulaID)
        case "pptx": return try await aulas.pptxSlides(try Data(contentsOf: url), into: aulaID)
        case "vvaula":
            let other = try await aulas.importPackage(try Data(contentsOf: url))
            defer { aulas.delete(other.id) }
            var out: [AulaSlide] = []
            for var s in other.slides {
                if let n = s.img, let d = try? Data(contentsOf: aulas.mediaURL(other.id, n)) { s.img = aulas.addMedia(d, name: n, to: aulaID) }
                s.id = UUID().uuidString
                out.append(s)
            }
            return out
        default:
            if let img = UIImage(contentsOfFile: url.path), let n = aulas.addImage(img, to: aulaID) {
                var s = AulaSlide(kind: .imagem)
                s.img = n
                return [s]
            }
            return []
        }
    }
}

/// Minhas aulas: lista, criar, importar.
struct AulasView: View {
    @EnvironmentObject private var aulas: AulaStore
    @EnvironmentObject private var nav: Nav
    @State private var importing = false
    @State private var busy: String?
    @State private var error: String?
    @State private var confirmDelete: Aula?

    private let theme = Theme.breve

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                HStack(spacing: 10) {
                    Button {
                        let a = aulas.create()
                        nav.push(.aula(a.id))
                    } label: { Label("Nova aula", systemImage: "plus") .frame(maxWidth: .infinity) }
                    .buttonStyle(PillStyle(kind: .gold))
                    Button { importing = true } label: { Label("Importar", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity) }
                    .buttonStyle(PillStyle(kind: .plain))
                }
                if aulas.aulas.isEmpty {
                    Button {
                        let a = aulas.create(Aula.sample())
                        nav.push(.aula(a.id))
                    } label: {
                        ToolTile(title: "Ver uma aula de exemplo", subtitle: "Uma aula pronta com todos os tipos de slide, para você conhecer e editar.", icon: "sparkles", primary: false)
                    }
                    .buttonStyle(PressStyle())
                } else {
                    SectionHeader("Suas aulas", trailing: "\(aulas.aulas.count)")
                    ForEach(aulas.aulas) { a in
                        Button { nav.push(.aula(a.id)) } label: { row(a) }
                            .buttonStyle(PressStyle())
                            .contextMenu {
                                Button { _ = aulas.duplicate(a.id) } label: { Label("Duplicar", systemImage: "plus.square.on.square") }
                                Button(role: .destructive) { confirmDelete = a } label: { Label("Apagar", systemImage: "trash") }
                            }
                    }
                }
            }
            .padding(16)
            .readable(760)
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "Minhas aulas")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.vvaula, .pptx, .pdf, .image, .zip]) { r in
            guard case .success(let url) = r else { return }
            run("Importando…") {
                let a = try await AulaImport.newAula(from: url, store: aulas)
                nav.push(.aula(a.id))
            }
        }
        .overlay { if let busy { BusyOverlay(text: busy) } }
        .alert("Não deu certo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
        .confirmationDialog("Apagar a aula “\(confirmDelete?.title ?? "")”?", isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }), titleVisibility: .visible) {
            Button("Apagar", role: .destructive) { if let a = confirmDelete { aulas.delete(a.id) } }
        }
    }

    private var intro: some View {
        HStack(alignment: .center, spacing: 14) {
            LumiView(mood: .idle).frame(width: 84, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("Monte a aula com calma, aqui no celular.")
                    .font(.display(.headline))
                    .foregroundStyle(Pal.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Na igreja, abra **\(SalaAPI.site)** no computador e passe os slides pelo celular. Também dá para baixar em PDF ou PowerPoint.")
                    .font(.footnote)
                    .foregroundStyle(Pal.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .card(radius: 20)
    }

    private func row(_ a: Aula) -> some View {
        HStack(spacing: 12) {
            if a.slides.isEmpty {
                RoundedRectangle(cornerRadius: 8).fill(Pal.line).frame(width: 112, height: 63)
            } else {
                SlideThumb(aula: a, index: 0).frame(width: 112)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(a.title).font(.headline).foregroundStyle(Pal.fg).lineLimit(2).multilineTextAlignment(.leading)
                Text("\(a.slides.count) slide\(a.slides.count == 1 ? "" : "s") · \(a.updatedText)")
                    .font(.footnote).foregroundStyle(Pal.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Pal.muted)
        }
        .padding(12)
        .card(radius: 18)
    }

    private func run(_ text: String, _ job: @escaping () async throws -> Void) {
        busy = text
        Task {
            do { try await job() } catch { self.error = error.localizedDescription }
            busy = nil
        }
    }
}

struct BusyOverlay: View {
    let text: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(Pal.gold)
                Text(text).font(.headline).foregroundStyle(Pal.fg)
            }
            .padding(26)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

/// Folha de compartilhar do sistema (AirDrop, WhatsApp, Arquivos, e-mail).
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct SharedFile: Identifiable {
    let url: URL
    var id: String { url.path }
}
