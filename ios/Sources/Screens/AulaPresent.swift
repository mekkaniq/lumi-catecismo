import SwiftUI
import UIKit

/// Apresentar no próprio aparelho (para ensaiar, ou ligado na TV pelo AirPlay espelhado).
struct AulaShowView: View {
    let aula: Aula
    @EnvironmentObject private var aulas: AulaStore
    @Environment(\.dismiss) private var dismiss
    @State private var cur = 0
    @State private var chrome = true
    @State private var images: [String: UIImage] = [:]

    var body: some View {
        let frames = aula.frames
        ZStack {
            Color.black.ignoresSafeArea()
            if !frames.isEmpty {
                SlideView(aula: aula, frame: frames[min(cur, frames.count - 1)], index: cur, total: frames.count, images: images)
                    .id(cur)
                    .transition(.opacity)
            }
            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle()).onTapGesture { go(-1, frames.count) }
                Color.clear.contentShape(Rectangle()).onTapGesture { go(1, frames.count) }
                    .frame(maxWidth: .infinity)
            }
            if chrome {
                VStack {
                    HStack {
                        Button { dismiss() } label: { Image(systemName: "xmark") }
                            .buttonStyle(GlassCircleStyle())
                            .accessibilityLabel("Fechar")
                        Spacer()
                        Text("\(cur + 1) / \(frames.count)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                    Spacer()
                    Text("Toque à direita para avançar e à esquerda para voltar")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(16)
                .transition(.opacity)
            }
        }
        .gesture(DragGesture(minimumDistance: 30).onEnded { v in
            if v.translation.width < -40 { go(1, frames.count) } else if v.translation.width > 40 { go(-1, frames.count) }
        })
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            images = Dictionary(uniqueKeysWithValues: aula.mediaNames.compactMap { n in aulas.image(aula.id, n).map { (n, $0) } })
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { chrome = false } }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func go(_ d: Int, _ n: Int) {
        let k = min(max(cur + d, 0), n - 1)
        guard k != cur else { if d > 0 && cur == n - 1 { withAnimation { chrome = true } }; return }
        withAnimation(.easeInOut(duration: 0.25)) { cur = k }
        Haptics.tap()
    }
}

/// Celular como controle da apresentação no computador da igreja.
struct RemoteView: View {
    let aula: Aula
    @EnvironmentObject private var aulas: AulaStore
    @Environment(\.dismiss) private var dismiss

    enum Phase: Equatable { case code, sending, control }
    @State private var phase: Phase = .code
    @State private var code = ""
    @State private var error: String?
    @State private var cur = 0
    @State private var online = false
    @State private var loaded = false
    @State private var black = false
    @State private var lastSend = Date.distantPast
    @State private var poll: Task<Void, Never>?
    @State private var images: [String: UIImage] = [:]
    @FocusState private var codeFocus: Bool

    private let theme = Theme.breve

    var body: some View {
        NavigationStack {
            ZStack {
                Pal.bg.ignoresSafeArea()
                switch phase {
                case .code: codeEntry
                case .sending: sending
                case .control: control
                }
            }
            .navigationTitle(phase == .control ? aula.title : "Apresentar no computador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.deep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(phase == .control ? "Encerrar" : "Fechar") { finish() }
                }
            }
        }
        .environment(\.theme, theme)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            images = Dictionary(uniqueKeysWithValues: aula.mediaNames.compactMap { n in aulas.image(aula.id, n).map { (n, $0) } })
            if ProcessInfo.processInfo.arguments.contains("-remotedemo") { code = "123456"; cur = 1; online = true; loaded = true; phase = .control }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            poll?.cancel()
        }
    }

    // MARK: código

    private var codeEntry: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Pal.gold)
                    Text("No computador da igreja, abra")
                        .font(.subheadline).foregroundStyle(Pal.muted)
                    Text(SalaAPI.site)
                        .font(.title3.weight(.bold)).foregroundStyle(Pal.fg)
                        .textSelection(.enabled)
                    Button {
                        UIPasteboard.general.string = "https://" + SalaAPI.site
                        Haptics.success()
                    } label: { Label("Copiar endereço", systemImage: "doc.on.doc") }
                    .font(.footnote.weight(.semibold))
                    .tint(Pal.gold)
                }
                VStack(spacing: 10) {
                    Text("Digite o código que aparece na tela")
                        .font(.headline).foregroundStyle(Pal.fg)
                    TextField("000000", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .tracking(8)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .background(Pal.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Pal.line, lineWidth: 1))
                        .focused($codeFocus)
                        .onChange(of: code) { _, v in
                            let d = String(v.filter(\.isNumber).prefix(6))
                            if d != v { code = d }
                        }
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(Pal.bad).multilineTextAlignment(.center)
                    }
                    Button { connect() } label: { Text("Enviar a aula e começar").frame(maxWidth: .infinity) }
                        .buttonStyle(PillStyle(kind: .gold))
                        .disabled(code.count != 6)
                }
                Text("O computador precisa de internet. O celular pode estar no Wi-Fi ou no 4G/5G.")
                    .font(.footnote).foregroundStyle(Pal.muted).multilineTextAlignment(.center)
            }
            .padding(22)
            .readable(520)
        }
        .onAppear { codeFocus = true }
    }

    private var sending: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large).tint(Pal.gold)
            Text("Enviando a aula para o computador…").font(.headline).foregroundStyle(Pal.fg)
            Text("\(aula.slides.count) slides").font(.footnote).foregroundStyle(Pal.muted)
        }
    }

    // MARK: controle

    private var control: some View {
        let frames = aula.frames
        let f = frames.isEmpty ? Frame(i: 0, step: 0) : frames[min(cur, frames.count - 1)]
        let next = cur + 1 < frames.count ? frames[cur + 1] : nil
        let s = aula.slides.isEmpty ? AulaSlide(kind: .titulo) : aula.slides[f.i]
        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(online ? Pal.ok : Pal.bad).frame(width: 9, height: 9)
                Text(online ? (loaded ? "Computador conectado" : "Computador carregando a aula…") : "Sem sinal do computador")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Pal.muted)
                Spacer()
                Text("\(cur + 1) / \(frames.count)").font(.footnote.weight(.bold)).foregroundStyle(Pal.fg)
            }
            SlideView(aula: aula, frame: f, index: cur, total: frames.count, images: images)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { if black { RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.85)).overlay(Text("Tela escura").foregroundStyle(.white)) } }
                .shadow(color: .black.opacity(0.25), radius: 10, y: 5)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ANOTAÇÕES").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Pal.muted)
                    ScrollView {
                        Text(s.notes.isEmpty ? (s.kind.hasReveal && f.step == 0 ? "Próximo toque revela a resposta." : "Sem anotações neste slide.") : s.notes)
                            .font(.callout)
                            .foregroundStyle(s.notes.isEmpty ? Pal.muted : Pal.fg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRÓXIMO").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Pal.muted)
                    if let next {
                        SlideView(aula: aula, frame: next, index: cur + 1, total: frames.count, images: images, showFooter: false)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Text("Fim da aula").font(.footnote).foregroundStyle(Pal.muted)
                    }
                }
                .frame(width: 130)
            }
            .padding(12)
            .frame(maxHeight: .infinity)
            .card(radius: 16)

            HStack(spacing: 12) {
                Button { go(cur - 1) } label: { Image(systemName: "chevron.left").font(.title2.weight(.bold)).frame(width: 70, height: 64) }
                    .buttonStyle(BigPadStyle(fill: Pal.surface, fg: Pal.fg))
                    .disabled(cur == 0)
                    .accessibilityLabel("Voltar")
                Button { go(cur + 1) } label: {
                    HStack { Text(next != nil ? (s.kind.hasReveal && f.step == 0 ? "Revelar" : "Avançar") : "Fim"); Image(systemName: "chevron.right") }
                        .font(.title3.weight(.bold)).frame(maxWidth: .infinity).frame(height: 64)
                }
                .buttonStyle(BigPadStyle(fill: Pal.gold, fg: Pal.ink))
                .disabled(next == nil)
                Button { toggleBlack() } label: { Image(systemName: black ? "sun.max.fill" : "moon.fill").font(.title2).frame(width: 64, height: 64) }
                    .buttonStyle(BigPadStyle(fill: Pal.surface, fg: Pal.fg))
                    .accessibilityLabel(black ? "Mostrar o slide" : "Escurecer a tela")
            }
        }
        .padding(16)
        .readable(700)
    }

    // MARK: ações

    private func connect() {
        error = nil
        let c = code
        phase = .sending
        Task {
            do {
                let info = try await SalaAPI.info(c)
                if !info.existe { throw SalaAPI.Failure.noRoom }
                let url = try await aulas.exportPackage(aulas.save(aula, touch: false))
                let data = try Data(contentsOf: url)
                try await SalaAPI.upload(c, file: data, startAt: cur)
                online = info.online
                loaded = false
                phase = .control
                lastSend = Date()
                startPolling()
                Haptics.success()
            } catch {
                self.error = error.localizedDescription
                phase = .code
                Haptics.miss()
            }
        }
    }

    private func startPolling() {
        poll?.cancel()
        let c = code
        poll = Task {
            while !Task.isCancelled {
                if let i = try? await SalaAPI.info(c) {
                    online = i.online
                    loaded = i.carregada
                    // Se passaram o slide no teclado do computador, o celular acompanha.
                    if i.carregada && i.quadro != cur && Date().timeIntervalSince(lastSend) > 4 {
                        cur = min(max(i.quadro, 0), max(aula.frames.count - 1, 0))
                    }
                } else {
                    online = false
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private func go(_ k: Int) {
        let n = aula.frames.count
        let t = min(max(k, 0), n - 1)
        guard t != cur else { return }
        cur = t
        lastSend = Date()
        Haptics.tap()
        if black { black = false }
        let c = code
        Task { try? await SalaAPI.broadcast(c, ["t": "go", "f": t]) }
    }

    private func toggleBlack() {
        black.toggle()
        lastSend = Date()
        let c = code, on = black
        Task { try? await SalaAPI.broadcast(c, ["t": "black", "on": on]) }
    }

    private func finish() {
        poll?.cancel()
        if phase == .control && code.count == 6 {
            let c = code
            Task { try? await SalaAPI.broadcast(c, ["t": "end"]) }
        }
        dismiss()
    }
}

struct BigPadStyle: ButtonStyle {
    let fill: Color
    let fg: Color
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(fg)
            .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Pal.line.opacity(0.6), lineWidth: 1))
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
