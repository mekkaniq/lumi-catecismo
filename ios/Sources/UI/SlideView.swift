import SwiftUI
import UIKit

/// Um slide da aula em 16:9. Desenhado num palco de 1600 x 900 e redimensionado para caber
/// (o mesmo layout do site de apresentação e do PowerPoint).
struct SlideView: View {
    let aula: Aula
    let frame: Frame
    var index = 0
    var total = 1
    var images: [String: UIImage] = [:]
    var showFooter = true

    private var s: AulaSlide { aula.slides[min(frame.i, max(aula.slides.count - 1, 0))] }
    private var T: SlideTheme { SlideTheme.of(aula.theme) }
    private func c(_ h: UInt32) -> Color { Color(hex: h) }
    private func px(_ pt: CGFloat) -> CGFloat { (pt * 1600 / 960).rounded() }
    private func fit(_ t: String, _ a: CGFloat, _ b: CGFloat, _ n: CGFloat) -> CGFloat { px(SlideFit.size(t, a, b, n)) }

    private let L: CGFloat = 84
    private var W: CGFloat { 1600 - 2 * L }

    var body: some View {
        GeometryReader { g in
            let k = min(g.size.width / 1600, g.size.height / 900)
            stage
                .frame(width: 1600, height: 900)
                .scaleEffect(k, anchor: .topLeading)
                .frame(width: 1600 * k, height: 900 * k, alignment: .topLeading)
                .position(x: g.size.width / 2, y: g.size.height / 2)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
    }

    @ViewBuilder
    private var stage: some View {
        if aula.slides.isEmpty {
            backdrop
        } else {
            ZStack(alignment: .topLeading) {
                if s.kind == .pagina { Color.black } else { backdrop }
                content
                if showFooter && s.kind != .pagina { footer }
            }
            .frame(width: 1600, height: 900, alignment: .topLeading)
            .clipped()
        }
    }

    private var backdrop: some View {
        ZStack {
            c(T.bg)
            RadialGradient(stops: [
                .init(color: c(T.bg2).opacity(0.95), location: 0),
                .init(color: c(T.bg2).opacity(0.35), location: 0.55),
                .init(color: c(T.bg2).opacity(0), location: 1),
            ], center: UnitPoint(x: 0.72, y: 0.18), startRadius: 0, endRadius: 1200)
            RadialGradient(colors: [c(T.accent).opacity(T.id == "claro" ? 0.18 : 0.22), .clear], center: UnitPoint(x: 0.8, y: 0.1), startRadius: 0, endRadius: 520)
            LinearGradient(stops: [.init(color: c(T.bg).opacity(0), location: 0.55), .init(color: c(T.bg).opacity(0.55), location: 1)], startPoint: .top, endPoint: .bottom)
        }
        .frame(width: 1600, height: 900)
    }

    private func label(_ t: String, _ y: CGFloat) -> some View {
        Text(t.uppercased())
            .font(.system(size: 23, weight: .bold))
            .tracking(4.5)
            .foregroundStyle(c(T.accent))
            .frame(width: W, alignment: .leading)
            .offset(x: L, y: y)
    }

    private func serif(_ t: String, _ size: CGFloat, weight: Font.Weight = .bold, italic: Bool = false) -> some View {
        Text(t)
            .font(.system(size: size, weight: weight, design: .serif))
            .italic(italic)
            .lineSpacing(size * 0.12)
            .foregroundStyle(c(T.fg))
            .minimumScaleFactor(0.5)
    }

    private func pic(_ name: String?, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        Group {
            if let n = name, let im = images[n] {
                Image(uiImage: im).resizable().scaledToFit().frame(width: w, height: h)
            } else if name != nil {
                RoundedRectangle(cornerRadius: 24).fill(c(T.card)).frame(width: w, height: h)
                    .overlay(Image(systemName: "photo").font(.system(size: 80)).foregroundStyle(c(T.muted)))
            }
        }
        .offset(x: x, y: y)
    }

    @ViewBuilder
    private var content: some View {
        switch s.kind {
        case .titulo:
            if !s.text.isEmpty { label(s.text, 330) }
            serif(s.title.isEmpty ? "Título" : s.title, fit(s.title, 54, 34, 90))
                .frame(width: W, height: 230, alignment: .topLeading)
                .offset(x: L, y: 390)
            if let sub = s.items.first, !sub.isEmpty {
                Text(sub).font(.system(size: 36)).foregroundStyle(c(T.muted))
                    .frame(width: W, alignment: .leading).offset(x: L, y: 640)
            }

        case .catecismo:
            label(s.label.isEmpty ? "Catecismo" : s.label, 80)
            if frame.step == 0 {
                serif(s.q.isEmpty ? "Escolha uma pergunta" : s.q, fit(s.q, 48, 32, 160))
                    .frame(width: W, height: 640, alignment: .leading)
                    .offset(x: L, y: 150)
            } else {
                serif(s.q, fit(s.q, 30, 22, 160))
                    .frame(width: W, height: 270, alignment: .topLeading)
                    .offset(x: L, y: 150)
                serif(s.a, fit(s.a, 34, 16, 900), weight: .regular)
                    .padding(.horizontal, 36).padding(.vertical, 30)
                    .frame(width: W, height: s.r.isEmpty ? 370 : 310, alignment: .topLeading)
                    .background(c(T.card), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(c(T.accent).opacity(0.33), lineWidth: 1.5))
                    .offset(x: L, y: 440)
                if !s.r.isEmpty {
                    Text(s.r).font(.system(size: 20)).foregroundStyle(c(T.muted))
                        .frame(width: W, alignment: .leading).offset(x: L, y: 768)
                }
            }

        case .biblia:
            serif("“" + (s.text.isEmpty ? "Texto bíblico" : s.text) + "”", fit(s.text, 40, 20, 700), weight: .regular, italic: true)
                .multilineTextAlignment(.center)
                .frame(width: W - 120, height: 600)
                .offset(x: L + 60, y: 110)
            Text(s.ref + (s.version.isEmpty ? "" : " · " + s.version))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(c(T.accent))
                .frame(width: 1600)
                .offset(y: 730)

        case .topicos:
            let items = s.items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if !s.title.isEmpty {
                serif(s.title, fit(s.title, 40, 28, 80)).frame(width: W, alignment: .leading).offset(x: L, y: 80)
            }
            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, t in
                    HStack(alignment: .firstTextBaseline, spacing: 22) {
                        Circle().fill(c(T.accent)).frame(width: 14, height: 14).offset(y: -4)
                        Text(t).font(.system(size: fit(items.joined(separator: " "), 28, 16, 700)))
                            .foregroundStyle(c(T.fg))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(width: s.img == nil ? W : 1080, alignment: .leading)
            .offset(x: L, y: s.title.isEmpty ? 120 : 250)
            pic(s.img, 1200, 250, 330, 500)

        case .imagem:
            pic(s.img ?? "", L, 70, W, s.title.isEmpty ? 740 : 640)
            if !s.title.isEmpty {
                Text(s.title).font(.system(size: 34)).foregroundStyle(c(T.fg)).frame(width: 1600).offset(y: 735)
            }

        case .pagina:
            pic(s.img ?? "", 0, 0, 1600, 900)

        case .discussao:
            label(s.text.isEmpty ? "Para conversar" : s.text, 190)
            serif(s.title.isEmpty ? "Pergunta para a turma" : s.title, fit(s.title, 46, 28, 220))
                .frame(width: W, height: 520, alignment: .leading)
                .offset(x: L, y: 260)

        case .quiz:
            serif(s.title.isEmpty ? "Pergunta do quiz" : s.title, fit(s.title, 38, 24, 180))
                .frame(width: W, height: 260, alignment: .leading)
                .offset(x: L, y: 70)
            let opts = Array(s.items.prefix(4))
            let cw = (W - 40) / 2
            ForEach(Array(opts.enumerated()), id: \.offset) { j, o in
                let right = frame.step == 1 && j == s.ok
                let dim = frame.step == 1 && !right
                HStack(spacing: 18) {
                    Text(["A", "B", "C", "D"][j]).font(.system(size: 40, weight: .bold))
                        .foregroundStyle(right ? Color(hex: 0x10200C) : c(T.accent))
                    Text(o.isEmpty ? "Opção" : o).font(.system(size: fit(o, 26, 16, 120)))
                        .foregroundStyle(right ? Color(hex: 0x10200C) : c(T.fg))
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 30)
                .frame(width: cw, height: 200, alignment: .leading)
                .background(right ? c(T.ok) : c(T.card), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(right ? c(T.ok) : c(T.accent).opacity(0.33), lineWidth: 1.5))
                .opacity(dim ? 0.45 : 1)
                .offset(x: L + CGFloat(j % 2) * (cw + 40), y: 370 + CGFloat(j / 2) * 230)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Rectangle().fill(c(T.accent).opacity(0.4)).frame(height: 2)
            HStack {
                Text(aula.title)
                Spacer()
                Text("\(index + 1) / \(total)")
            }
            .font(.system(size: 18))
            .foregroundStyle(c(T.muted))
        }
        .frame(width: W)
        .offset(x: L, y: 834)
    }
}

/// Miniatura de um slide (carrega as imagens da aula).
struct SlideThumb: View {
    let aula: Aula
    let index: Int
    var step = 0
    @EnvironmentObject private var aulas: AulaStore

    var body: some View {
        let imgs = Dictionary(uniqueKeysWithValues: [aula.slides[index].img].compactMap { $0 }.compactMap { n in aulas.image(aula.id, n).map { (n, $0) } })
        SlideView(aula: aula, frame: Frame(i: index, step: step), index: index, total: aula.slides.count, images: imgs, showFooter: false)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Pal.line.opacity(0.6), lineWidth: 1))
    }
}
