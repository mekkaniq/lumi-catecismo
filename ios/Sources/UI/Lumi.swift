import SwiftUI

enum LumiPose: String {
    case oi, festa, pensando, dica, lendo, dormindo, sarca, rosto
}

extension LumiMood {
    var pose: LumiPose {
        switch self {
        case .idle: return .lendo
        case .happy: return .oi
        case .cheer: return .festa
        case .think, .meh, .sad: return .pensando
        case .sleep: return .dormindo
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var t: CGFloat
    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(t * .pi * 8), y: 0))
    }
}

/// A Lumi (ilustração) com respiração suave e reação a acertos e erros.
struct LumiView: View {
    var mood: LumiMood
    var pose: LumiPose? = nil
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hop: CGFloat = 0
    @State private var shake: CGFloat = 0

    private var activePose: LumiPose { pose ?? mood.pose }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !animated)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let breathe = reduceMotion || !animated ? 0 : sin(t * 2.0)
            Image("lumi-\(activePose.rawValue)")
                .resizable()
                .scaledToFit()
                .saturation(mood == .sad ? 0.55 : mood == .meh ? 0.85 : 1)
                .rotationEffect(.degrees(mood == .meh ? 5 : 0), anchor: .bottom)
                .scaleEffect(x: 1 + 0.008 * breathe, y: 1 + 0.018 * breathe, anchor: .bottom)
                .overlay(alignment: .topLeading) { if mood == .sad { tear } }
        }
        .offset(y: hop)
        .modifier(ShakeEffect(t: shake))
        .onChange(of: mood) { _, new in react(new) }
        .accessibilityHidden(true)
    }

    private var tear: some View {
        GeometryReader { g in
            Image(systemName: "drop.fill")
                .font(.system(size: g.size.width * 0.07))
                .foregroundStyle(Color(hex: 0x7cc4f0))
                .position(x: g.size.width * 0.34, y: g.size.height * 0.34)
        }
    }

    private func react(_ m: LumiMood) {
        guard animated, !reduceMotion else { return }
        if m == .sad {
            withAnimation(.linear(duration: 0.5)) { shake += 1 }
        } else if m == .happy || m == .cheer || m == .meh {
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.16)) { hop = -14 }
                try? await Task.sleep(nanoseconds: 160_000_000)
                withAnimation(.interpolatingSpring(stiffness: 260, damping: 12)) { hop = 0 }
            }
        }
    }
}

/// A Lumi brincando com os três livros (recepção).
struct BooksScene: View {
    var open: (String) -> Void

    private let ox: CGFloat = 0
    private let oy: CGFloat = 30
    @State private var phrase: String? = nil

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 330
            ZStack(alignment: .topLeading) {
                Ellipse()
                    .fill(Color.black.opacity(0.32))
                    .frame(width: 270 * s, height: 20 * s)
                    .blur(radius: 5 * s)
                    .position(x: 195 * s, y: (186 + oy) * s)

                bookH("maior", x: 96, y: 150, w: 190, h: 30, label: "CATECISMO MAIOR", left: false, s: s)
                bookH("conf", x: 110, y: 121, w: 164, h: 29, label: "CONFISSÃO", left: true, s: s)
                bookV(s: s)

                PlayfulLumi(basePose: .dica) { p in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { phrase = p }
                }
                .frame(width: 128 * s, height: 140 * s)
                .position(x: 182 * s, y: (121 + oy - 62) * s)

                if let phrase {
                    SpeechPop(text: phrase, size: 11.5 * s)
                        .frame(width: 112 * s)
                        .position(x: 60 * s, y: (50 + oy) * s)
                        .transition(.scale(scale: 0.6, anchor: .trailing).combined(with: .opacity))
                        .allowsHitTesting(false)
                }

                Image(systemName: "sparkle")
                    .font(.system(size: 14 * s))
                    .foregroundStyle(Pal.brightGold)
                    .position(x: 262 * s, y: (40 + oy) * s)
                Image(systemName: "sparkle")
                    .font(.system(size: 9 * s))
                    .foregroundStyle(Pal.brightGold.opacity(0.8))
                    .position(x: 70 * s, y: (92 + oy) * s)
            }
        }
        .aspectRatio(330.0 / 222.0, contentMode: .fit)
    }

    private func bookH(_ id: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, label: String, left: Bool, s: CGFloat) -> some View {
        let t = Theme.of(id)
        return Button { open(id) } label: {
            ZStack(alignment: left ? .leading : .center) {
                RoundedRectangle(cornerRadius: 4 * s, style: .continuous)
                    .fill(LinearGradient(colors: [t.spine.opacity(1), t.spine.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 4 * s, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
                HStack(spacing: 0) {
                    Rectangle().fill(Pal.brightGold.opacity(0.9)).frame(width: 2.4 * s)
                    Spacer()
                    Rectangle().fill(Pal.brightGold.opacity(0.9)).frame(width: 2.4 * s)
                }
                .padding(.horizontal, 9 * s)
                Text(label)
                    .font(.system(size: 10 * s, weight: .bold, design: .serif))
                    .tracking(1.4 * s)
                    .foregroundStyle(Pal.cream)
                    .padding(.leading, left ? 15 * s : 0)
            }
            .frame(width: w * s, height: h * s)
            .shadow(color: .black.opacity(0.35), radius: 4 * s, y: 3 * s)
        }
        .buttonStyle(PressStyle())
        .position(x: (x + w / 2) * s, y: (y + oy + h / 2) * s)
        .accessibilityLabel("Abrir \(Library.book(id).name)")
    }

    private func bookV(s: CGFloat) -> some View {
        let t = Theme.breve
        return Button { open("breve") } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4 * s, style: .continuous)
                    .fill(LinearGradient(colors: [t.spine, t.spine.opacity(0.78)], startPoint: .leading, endPoint: .trailing))
                RoundedRectangle(cornerRadius: 4 * s, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .leading, endPoint: .center))
                VStack {
                    Rectangle().fill(Pal.brightGold).frame(height: 2.4 * s)
                    Spacer()
                    Rectangle().fill(Pal.brightGold).frame(height: 2.4 * s)
                }
                .padding(.vertical, 9 * s)
                Text("BREVE")
                    .font(.system(size: 9.5 * s, weight: .bold, design: .serif))
                    .tracking(1.2 * s)
                    .foregroundStyle(Pal.cream)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 30 * s, height: 94 * s)
            .shadow(color: .black.opacity(0.35), radius: 4 * s, y: 3 * s)
        }
        .buttonStyle(PressStyle())
        .position(x: 307 * s, y: (86 + oy + 47) * s)
        .accessibilityLabel("Abrir Breve Catecismo")
    }
}


/// Balão curto ao lado da Lumi, com a pontinha apontando para ela.
struct SpeechPop: View {
    let text: String
    var size: CGFloat = 12

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: 0x1d2420))
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .trailing) {
                Triangle()
                    .fill(.white)
                    .frame(width: 10, height: 12)
                    .rotationEffect(.degrees(135))
                    .offset(x: 6, y: 6)
            }
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

/// A Lumi que reage ao toque: ri de cócegas, dança, pula, dá uma voltinha, cochila e fala.
struct PlayfulLumi: View {
    var basePose: LumiPose = .dica
    var onPhrase: (String?) -> Void

    private enum Act { case tickle, hop, dance, spin, calm }
    private struct Move {
        let act: Act
        let pose: LumiPose
        let text: String
    }

    private let moves: [Move] = [
        Move(act: .tickle, pose: .festa, text: "Hihi! Cócegas! Pare, pare!"),
        Move(act: .hop, pose: .oi, text: "Oi! Que bom que você veio!"),
        Move(act: .dance, pose: .festa, text: "Vou dançar para a glória de Deus!"),
        Move(act: .calm, pose: .dica, text: "O fim principal do homem é glorificar a Deus e gozá-lo para sempre."),
        Move(act: .calm, pose: .dica, text: "Toque num livro e vamos estudar juntos!"),
        Move(act: .calm, pose: .dormindo, text: "Zzz… ah! Você me acordou!"),
        Move(act: .calm, pose: .pensando, text: "Hmm… qual será a pergunta de hoje?"),
        Move(act: .tickle, pose: .oi, text: "Ei! Isso faz cócegas, viu?"),
        Move(act: .hop, pose: .festa, text: "Eba! Vamos aprender!"),
        Move(act: .dance, pose: .oi, text: "Lá lá lá! Quem quer dançar comigo?"),
    ]

    @State private var pose: LumiPose? = nil
    @State private var rot: Double = 0
    @State private var hop: CGFloat = 0
    @State private var turn: Double = 0
    @State private var taps: [Date] = []
    @State private var last = -1
    @State private var job: Task<Void, Never>? = nil

    var body: some View {
        LumiView(mood: .happy, pose: pose ?? basePose)
            .rotationEffect(.degrees(rot), anchor: .bottom)
            .offset(y: hop)
            .rotation3DEffect(.degrees(turn), axis: (x: 0, y: 1, z: 0))
            .contentShape(Rectangle())
            .onTapGesture { tap() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Lumi. Toque para brincar com ela")
            .accessibilityAddTraits(.isButton)
            .onAppear {
                // só para a captura de tela do CI
                if ProcessInfo.processInfo.arguments.contains("-lumitap") {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 3_800_000_000)
                        tap()
                    }
                }
            }
    }

    private func tap() {
        let now = Date()
        taps = taps.filter { now.timeIntervalSince($0) < 2.5 } + [now]
        job?.cancel()
        let move: Move
        if taps.count >= 6 {
            move = Move(act: .spin, pose: .festa, text: "Hahaha! Chega, chega! Cócegas demais!")
            taps = []
        } else {
            var k = Int.random(in: 0..<moves.count)
            while k == last { k = Int.random(in: 0..<moves.count) }
            last = k
            move = moves[k]
        }
        Haptics.tap()
        Speaker.shared.chatter(move.text)
        job = Task { @MainActor in await perform(move) }
    }

    @MainActor
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return !Task.isCancelled
    }

    @MainActor
    private func perform(_ m: Move) async {
        withAnimation(.easeOut(duration: 0.1)) { rot = 0; hop = 0 }
        pose = m.pose
        onPhrase(m.text)

        switch m.act {
        case .tickle:
            for i in 0..<7 {
                withAnimation(.easeInOut(duration: 0.07)) { rot = i % 2 == 0 ? 9 : -9 }
                guard await pause(0.08) else { return }
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { rot = 0 }
        case .hop:
            withAnimation(.easeOut(duration: 0.15)) { hop = -22 }
            guard await pause(0.16) else { return }
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { hop = 0 }
        case .dance:
            for i in 0..<8 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    rot = i % 2 == 0 ? 10 : -10
                    hop = i % 2 == 0 ? -10 : 0
                }
                guard await pause(0.22) else { return }
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { rot = 0; hop = 0 }
        case .spin:
            withAnimation(.easeInOut(duration: 0.8)) { turn += 360 }
            withAnimation(.easeOut(duration: 0.2)) { hop = -16 }
            guard await pause(0.4) else { return }
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { hop = 0 }
        case .calm:
            withAnimation(.easeOut(duration: 0.14)) { hop = -8 }
            guard await pause(0.15) else { return }
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 10)) { hop = 0 }
        }

        guard await pause(max(1.8, Double(m.text.count) * 0.055)) else { return }
        pose = nil
        onPhrase(nil)
    }
}
