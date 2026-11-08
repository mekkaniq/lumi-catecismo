import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Editor da aula: título, tema, slides (reordenar, apagar), importar, apresentar e exportar.
struct AulaEditView: View {
    let id: String
    @EnvironmentObject private var aulas: AulaStore
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var a: Aula = Aula()
    @State private var loaded = false
    @State private var editing: String?
    @State private var importing = false
    @State private var photos: [PhotosPickerItem] = []
    @State private var pickingPhotos = false
    @State private var share: SharedFile?
    @State private var busy: String?
    @State private var error: String?
    @State private var presentHere = false
    @State private var presentRemote = false

    private let theme = Theme.breve

    var body: some View {
        List {
            Section {
                TextField("Título da aula", text: $a.title, axis: .vertical)
                    .font(.display(.title3))
                    .foregroundStyle(Pal.fg)
                themePicker
            }
            .listRowBackground(Pal.surface)

            Section {
                ForEach(Array(a.slides.enumerated()), id: \.element.id) { i, s in
                    Button { editing = s.id } label: { row(i, s) }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading) {
                            Button { duplicate(i) } label: { Label("Duplicar", systemImage: "plus.square.on.square") }.tint(theme.accent)
                        }
                }
                .onMove { a.slides.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { a.slides.remove(atOffsets: $0) }
                addMenu
            } header: {
                HStack {
                    Text("Slides · \(a.slides.count)")
                    Spacer()
                    Text("Arraste para reordenar").textCase(nil).font(.caption2)
                }
            } footer: {
                Text("Slides de catecismo e de quiz aparecem duas vezes na apresentação: primeiro a pergunta, depois a resposta.")
            }
            .listRowBackground(Pal.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: "Aula")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItemGroup(placement: .bottomBar) {
                Menu {
                    Button { presentRemote = true } label: { Label("No computador da igreja", systemImage: "desktopcomputer") }
                    Button { presentHere = true } label: { Label("Neste aparelho", systemImage: "iphone") }
                } label: { Label("Apresentar", systemImage: "play.rectangle.fill").labelStyle(.titleAndIcon) }
                    .disabled(a.slides.isEmpty)
                Spacer()
                Menu {
                    Button { exportPDF() } label: { Label("PDF", systemImage: "doc.richtext") }
                    Button { run("Gerando o PowerPoint…") { share = SharedFile(url: try await aulas.exportPptx(save())) } } label: { Label("PowerPoint (.pptx)", systemImage: "rectangle.on.rectangle") }
                    Button { run("Preparando o arquivo…") { share = SharedFile(url: try await aulas.exportPackage(save())) } } label: { Label("Arquivo da aula (para editar ou enviar)", systemImage: "square.and.arrow.up.on.square") }
                } label: { Label("Baixar", systemImage: "square.and.arrow.up").labelStyle(.titleAndIcon) }
                    .disabled(a.slides.isEmpty)
            }
        }
        .sheet(item: Binding(get: { editing.map { EditID(id: $0) } }, set: { editing = $0?.id })) { e in
            if let b = binding(e.id) {
                SlideEditor(aula: a, slide: b)
                    .environmentObject(aulas)
                    .environmentObject(store)
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .pptx, .vvaula, .image]) { r in
            guard case .success(let url) = r else { return }
            run("Importando…") {
                let new = try await AulaImport.slides(from: url, into: a.id, store: aulas)
                a.slides += new
                if new.isEmpty { throw AulaKitBridge.Failure.message("Nada para importar neste arquivo.") }
            }
        }
        .photosPicker(isPresented: $pickingPhotos, selection: $photos, maxSelectionCount: 30, matching: .images)
        .onChange(of: photos) { _, items in
            guard !items.isEmpty else { return }
            run("Trazendo as fotos…") {
                for it in items {
                    if let d = try await it.loadTransferable(type: Data.self), let img = UIImage(data: d), let n = aulas.addImage(img, to: a.id) {
                        var s = AulaSlide(kind: .imagem)
                        s.img = n
                        a.slides.append(s)
                    }
                }
                photos = []
            }
        }
        .sheet(item: $share) { f in ShareSheet(url: f.url).presentationDetents([.medium, .large]) }
        .fullScreenCover(isPresented: $presentHere) { AulaShowView(aula: save()).environmentObject(aulas) }
        .fullScreenCover(isPresented: $presentRemote) { RemoteView(aula: save()).environmentObject(aulas) }
        .overlay { if let busy { BusyOverlay(text: busy) } }
        .alert("Não deu certo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
        .onAppear {
            guard !loaded else { return }
            if let x = aulas.aula(id) { a = x }
            loaded = true
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-slideedit"), let s = a.slides.dropFirst().first { editing = s.id }
            if args.contains("-present") { presentHere = true }
            if args.contains("-remotedemo") { presentRemote = true }
            if args.contains("-exporttest") { exportTest() }
        }
        .onChange(of: a) { _, new in if loaded { aulas.save(new) } }
    }

    struct EditID: Identifiable { let id: String }

    private func binding(_ sid: String) -> Binding<AulaSlide>? {
        guard a.slides.contains(where: { $0.id == sid }) else { return nil }
        return Binding(
            get: { a.slides.first(where: { $0.id == sid }) ?? AulaSlide(kind: .titulo) },
            set: { v in if let i = a.slides.firstIndex(where: { $0.id == sid }) { a.slides[i] = v } }
        )
    }

    @discardableResult
    private func save() -> Aula { aulas.save(a) }

    private var themePicker: some View {
        HStack(spacing: 12) {
            Text("Cores").font(.subheadline).foregroundStyle(Pal.muted)
            Spacer()
            ForEach(SlideTheme.all, id: \.id) { t in
                Button { a.theme = t.id } label: {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: t.bg2), Color(hex: t.bg)], startPoint: .topTrailing, endPoint: .bottomLeading))
                        .overlay(Circle().fill(Color(hex: t.accent)).frame(width: 9, height: 9).offset(x: 7, y: -7))
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(a.theme == t.id ? Pal.gold : Pal.line, lineWidth: a.theme == t.id ? 3 : 1).padding(-3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cores: \(t.name)")
            }
        }
        .padding(.vertical, 4)
    }

    private func row(_ i: Int, _ s: AulaSlide) -> some View {
        HStack(spacing: 12) {
            SlideThumb(aula: a, index: i).frame(width: 104)
            VStack(alignment: .leading, spacing: 3) {
                Label(s.kind.name, systemImage: s.kind.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text(s.summary)
                    .font(.subheadline)
                    .foregroundStyle(Pal.fg)
                    .lineLimit(2)
                if !s.notes.isEmpty {
                    Label("Com anotação", systemImage: "note.text").font(.caption2).foregroundStyle(Pal.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private var addMenu: some View {
        Menu {
            Section("Novo slide") {
                ForEach(SlideKind.creatable) { k in
                    Button { add(k) } label: { Label(k.name, systemImage: k.icon) }
                }
            }
            Section("Trazer de fora") {
                Button { pickingPhotos = true } label: { Label("Fotos", systemImage: "photo.on.rectangle") }
                Button { importing = true } label: { Label("PDF, PowerPoint ou outra aula", systemImage: "folder") }
            }
        } label: {
            Label("Adicionar slide", systemImage: "plus.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.accent)
                .padding(.vertical, 6)
        }
    }

    private func add(_ k: SlideKind) {
        var s = AulaSlide(kind: k)
        if k == .catecismo {
            let book = Library.book(store.lastBook ?? "breve")
            let n = (store.last(book.id).map { book.units[$0].a }) ?? 1
            fillCatechism(&s, book: book, n: n)
        }
        a.slides.append(s)
        editing = s.id
    }

    private func duplicate(_ i: Int) {
        var s = a.slides[i]
        s.id = UUID().uuidString
        a.slides.insert(s, at: i + 1)
    }

    private func exportPDF() {
        let x = save()
        busy = "Gerando o PDF…"
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            if let url = aulas.exportPDF(x) { share = SharedFile(url: url) } else { error = "Não consegui gerar o PDF." }
            busy = nil
        }
    }

    /// Só para o CI: gera PDF, PowerPoint e arquivo da aula em Documentos/export-test.
    private func exportTest() {
        let x = save()
        Task {
            let out = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("export-test", isDirectory: true)
            try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            var log = ""
            if let u = aulas.exportPDF(x) { try? FileManager.default.copyItem(at: u, to: out.appendingPathComponent("aula.pdf")); log += "pdf ok\n" } else { log += "pdf FALHOU\n" }
            do { let u = try await aulas.exportPptx(x); try FileManager.default.copyItem(at: u, to: out.appendingPathComponent("aula.pptx")); log += "pptx ok\n" } catch { log += "pptx FALHOU: \(error.localizedDescription)\n" }
            do {
                let u = try await aulas.exportPackage(x)
                try FileManager.default.copyItem(at: u, to: out.appendingPathComponent("aula.vvaula"))
                let back = try await aulas.importPackage(try Data(contentsOf: u))
                log += "vvaula ok, reaberta com \(back.slides.count) slides\n"
                aulas.delete(back.id)
            } catch { log += "vvaula FALHOU: \(error.localizedDescription)\n" }
            try? log.write(to: out.appendingPathComponent("log.txt"), atomically: true, encoding: .utf8)
        }
    }

    private func run(_ text: String, _ job: @escaping () async throws -> Void) {
        busy = text
        Task {
            do { try await job() } catch { self.error = error.localizedDescription }
            busy = nil
        }
    }
}

func fillCatechism(_ s: inout AulaSlide, book: Book, n: Int) {
    let x = book.item(n)
    s.book = book.id
    s.n = n
    s.label = "\(book.name) · \(x.label)"
    s.q = x.q
    s.a = x.a
    s.r = x.r
}

/// Edição de um slide, com prévia ao vivo.
struct SlideEditor: View {
    let aula: Aula
    @Binding var slide: AulaSlide
    @EnvironmentObject private var aulas: AulaStore
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var photo: PhotosPickerItem?
    @State private var pickingQuestion = false

    private var preview: Aula {
        var x = aula
        if let i = x.slides.firstIndex(where: { $0.id == slide.id }) { x.slides[i] = slide }
        return x
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 10) {
                        let p = preview
                        let i = p.slides.firstIndex(where: { $0.id == slide.id }) ?? 0
                        let imgs = Dictionary(uniqueKeysWithValues: [slide.img].compactMap { $0 }.compactMap { n in aulas.image(aula.id, n).map { (n, $0) } })
                        SlideView(aula: p, frame: Frame(i: i, step: slide.kind.hasReveal ? step : 0), index: i, total: p.slides.count, images: imgs)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        if slide.kind.hasReveal {
                            Picker("Prévia", selection: $step) {
                                Text("Pergunta").tag(0)
                                Text("Resposta").tag(1)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                }

                fields

                Section {
                    TextField("O que você quer lembrar ao mostrar este slide", text: $slide.notes, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Anotações do professor")
                } footer: {
                    Text("Aparecem só no celular, quando ele controla a apresentação no computador.")
                }
            }
            .navigationTitle(slide.kind.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } } }
            .sheet(isPresented: $pickingQuestion) {
                let b = slide.book ?? store.lastBook ?? "breve"
                let book = Library.book(b)
                ClassPicker(bookID: b, u: slide.n.map { book.unitOf($0) } ?? -1, current: slide.n ?? 0) { id, _, n in
                    fillCatechism(&slide, book: Library.book(id), n: n)
                    pickingQuestion = false
                }
                .environmentObject(store)
            }
            .onChange(of: photo) { _, item in
                guard let item else { return }
                Task {
                    if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d), let n = aulas.addImage(img, to: aula.id) {
                        slide.img = n
                    }
                    photo = nil
                }
            }
        }
        .tint(Pal.gold)
    }

    @ViewBuilder
    private var fields: some View {
        switch slide.kind {
        case .titulo:
            Section("Texto") {
                TextField("Linha de cima (ex.: Escola Dominical · 9 de novembro)", text: $slide.text, axis: .vertical)
                TextField("Título", text: $slide.title, axis: .vertical).font(.headline)
                TextField("Linha de baixo (ex.: nome do professor)", text: firstItem)
            }

        case .catecismo:
            Section {
                Button { pickingQuestion = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slide.label.isEmpty ? "Escolher pergunta" : slide.label).font(.caption.weight(.semibold)).foregroundStyle(Pal.gold)
                            Text(slide.q.isEmpty ? "Toque para escolher" : slide.q).foregroundStyle(Pal.fg)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Pal.muted)
                    }
                }
            } header: {
                Text("Pergunta do catecismo")
            } footer: {
                Text("Na apresentação, a resposta aparece no passo seguinte.")
            }

        case .biblia:
            Section {
                TextField("Referência (ex.: Salmo 23.1)", text: $slide.ref)
                TextField("Versão (ex.: ARA, ACF, NVI)", text: $slide.version)
                TextField("Cole aqui o texto", text: $slide.text, axis: .vertical).lineLimit(4...14)
            } header: {
                Text("Texto bíblico")
            } footer: {
                Text("Cole o texto da Bíblia que a igreja usa.")
            }

        case .topicos:
            Section("Título") {
                TextField("Título do slide", text: $slide.title, axis: .vertical)
            }
            Section {
                ForEach(slide.items.indices, id: \.self) { i in
                    TextField("Tópico \(i + 1)", text: Binding(get: { i < slide.items.count ? slide.items[i] : "" }, set: { if i < slide.items.count { slide.items[i] = $0 } }), axis: .vertical)
                }
                .onDelete { slide.items.remove(atOffsets: $0) }
                .onMove { slide.items.move(fromOffsets: $0, toOffset: $1) }
                if slide.items.count < 10 {
                    Button { slide.items.append("") } label: { Label("Adicionar tópico", systemImage: "plus") }
                }
            } header: {
                Text("Tópicos")
            }
            imageSection(optional: true)

        case .imagem:
            imageSection(optional: false)
            Section("Legenda") {
                TextField("Legenda (opcional)", text: $slide.title, axis: .vertical)
            }

        case .pagina:
            Section {
                Text("Página trazida de um PDF ou PowerPoint. Ela aparece inteira na tela.").font(.footnote).foregroundStyle(Pal.muted)
            }

        case .discussao:
            Section("Para conversar") {
                TextField("Etiqueta (ex.: Para conversar)", text: $slide.text)
                TextField("Pergunta para a turma", text: $slide.title, axis: .vertical).lineLimit(2...6)
            }

        case .quiz:
            Section("Pergunta") {
                TextField("Pergunta do quiz", text: $slide.title, axis: .vertical)
            }
            Section {
                ForEach(0..<4, id: \.self) { j in
                    HStack(spacing: 12) {
                        Button { slide.ok = j } label: {
                            Image(systemName: slide.ok == j ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(slide.ok == j ? Pal.ok : Pal.muted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Marcar \(["A", "B", "C", "D"][j]) como certa")
                        TextField("Opção \(["A", "B", "C", "D"][j])", text: Binding(
                            get: { j < slide.items.count ? slide.items[j] : "" },
                            set: { v in
                                while slide.items.count <= j { slide.items.append("") }
                                slide.items[j] = v
                            }), axis: .vertical)
                    }
                }
            } header: {
                Text("Opções")
            } footer: {
                Text("Toque no círculo para marcar a resposta certa. Ela fica verde no passo seguinte.")
            }
        }
    }

    private var firstItem: Binding<String> {
        Binding(get: { slide.items.first ?? "" }, set: { v in if slide.items.isEmpty { slide.items = [v] } else { slide.items[0] = v } })
    }

    private func imageSection(optional: Bool) -> some View {
        Section {
            PhotosPicker(selection: $photo, matching: .images) {
                Label(slide.img == nil ? "Escolher foto" : "Trocar foto", systemImage: "photo.on.rectangle")
            }
            if optional && slide.img != nil {
                Button(role: .destructive) { slide.img = nil } label: { Label("Tirar a foto", systemImage: "trash") }
            }
        } header: {
            Text(optional ? "Imagem (opcional)" : "Imagem")
        }
    }
}
