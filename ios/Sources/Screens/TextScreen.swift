import SwiftUI

struct TextScreen: View {
    let key: String
    private let theme = Theme.breve

    var body: some View {
        let t = Library.texts[key]
        ScrollView {
            if let t = t {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t.ref.uppercased())
                                .font(.caption.weight(.semibold))
                                .tracking(1.2)
                                .foregroundStyle(Pal.muted)
                            Text(t.t)
                                .font(.display(.largeTitle))
                                .foregroundStyle(Pal.fg)
                        }
                        Spacer()
                        LumiView(mood: .idle)
                            .frame(width: 92, height: 104)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        if let list = t.list {
                            ForEach(Array(list.enumerated()), id: \.offset) { i, s in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text("\(i + 1)")
                                        .font(.system(.headline, design: .serif))
                                        .foregroundStyle(Pal.gold)
                                        .frame(width: 26, alignment: .trailing)
                                    Text(s)
                                        .font(.system(.title3, design: .serif))
                                        .foregroundStyle(Pal.fg)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if let after = t.after {
                                Text(after)
                                    .font(.callout)
                                    .foregroundStyle(Pal.muted)
                                    .padding(.top, 4)
                            }
                        } else if let body = t.body {
                            Text(body)
                                .font(.system(.title3, design: .serif))
                                .lineSpacing(7)
                                .foregroundStyle(Pal.fg)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(radius: 24)

                    Button {
                        let spoken = t.list.map { l in l.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: " ") } ?? (t.body ?? "")
                        Speaker.shared.say(spoken)
                    } label: {
                        Label("Ouvir", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(PillStyle(kind: .solid))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .background(Pal.bg.ignoresSafeArea())
        .environment(\.theme, theme)
        .lumiBar(theme, solid: true, title: t?.t ?? "")
        .onDisappear { Speaker.shared.stop() }
    }
}
