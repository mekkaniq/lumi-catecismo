import SwiftUI

/// Fundo das telas: pergaminho no claro; no escuro, a paisagem do livro bem escurecida (como no site da editora).
struct Backdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Pal.bg
            if scheme == .dark {
                Color.clear
                    .overlay(Image(theme.world).resizable().scaledToFill())
                    .clipped()
                Color(hex: 0x120c06, opacity: 0.84)
            }
        }
        .ignoresSafeArea()
    }
}
