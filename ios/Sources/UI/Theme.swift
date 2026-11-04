import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: opacity)
    }
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { tc in
            tc.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

/// Cores comuns do app (claro = pergaminho, escuro = tinta quente com ouro: a identidade Verso Vivo).
enum Pal {
    static let bg = Color(light: 0xf7edd3, dark: 0x16100a)
    static let surface = Color(light: 0xfffaec, dark: 0x22190d)
    static let fg = Color(light: 0x2a1d0c, dark: 0xfbf1d8)
    static let muted = Color(light: 0x6d5c3b, dark: 0xcfc09a)
    static let line = Color(light: 0xd9c8a0, dark: 0x4a3b20)
    static let gold = Color(light: 0xc6912c, dark: 0xf0cd7e)
    static let ok = Color(light: 0x2f7d4a, dark: 0x9fd08a)
    static let okBg = Color(light: 0xe2f1e6, dark: 0x26331d)
    static let bad = Color(light: 0xb4472e, dark: 0xf0a08a)
    static let badBg = Color(light: 0xf8e6e0, dark: 0x3a2018)
    static let bubble = Color(light: 0xfffaf0, dark: 0xfbf1d8)
    static let ink = Color(hex: 0x2a1d0c)
    static let cream = Color(hex: 0xfbf1d8)
    static let brightGold = Color(hex: 0xf0cd7e)
}

/// Cores de cada livro (verde da IPB, vinho e azul-petróleo).
struct Theme {
    let accent: Color
    let primary: Color
    let deep: Color
    let soft: Color
    let glow: [Color]
    let spine: Color
    let world: String

    static func of(_ id: String) -> Theme {
        switch id {
        case "maior": return .maior
        case "conf": return .conf
        default: return .breve
        }
    }

    static let breve = Theme(
        accent: Color(light: 0x215732, dark: 0xa9cc7e),
        primary: Color(light: 0x215732, dark: 0x2c7a4b),
        deep: Color(light: 0x1a2412, dark: 0x1a2412),
        soft: Color(light: 0xe9eedb, dark: 0x252d18),
        glow: [Color(hex: 0x0e170a), Color(hex: 0x3d5a2a), Color(hex: 0xf0cd7e)],
        spine: Color(hex: 0x215732), world: "mundo1")

    static let maior = Theme(
        accent: Color(light: 0x7b2d35, dark: 0xe8a0a6),
        primary: Color(light: 0x7b2d35, dark: 0x94404a),
        deep: Color(light: 0x2a0f12, dark: 0x2a0f12),
        soft: Color(light: 0xf1dfd8, dark: 0x33191c),
        glow: [Color(hex: 0x1c0a0c), Color(hex: 0x7a2f38), Color(hex: 0xf0cd7e)],
        spine: Color(hex: 0x7b2d35), world: "mundo2")

    static let conf = Theme(
        accent: Color(light: 0x1f5068, dark: 0x8ec7e0),
        primary: Color(light: 0x1f5068, dark: 0x2c6a88),
        deep: Color(light: 0x0d202c, dark: 0x0d202c),
        soft: Color(light: 0xdfe9ec, dark: 0x15303d),
        glow: [Color(hex: 0x071720), Color(hex: 0x245a74), Color(hex: 0xf0cd7e)],
        spine: Color(hex: 0x1f5068), world: "mundo3")
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.breve
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension Font {
    /// Títulos em Cinzel (a mesma letra do site da editora); cresce com o tamanho de texto do sistema.
    static func display(_ style: Font.TextStyle) -> Font {
        .custom("Cinzel-Bold", size: displayBase(style), relativeTo: style)
    }

    private static func displayBase(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 31
        case .title: return 25
        case .title2: return 20
        case .title3: return 18
        case .headline: return 15
        case .body: return 15
        case .callout: return 14
        case .subheadline: return 13
        case .footnote: return 12
        case .caption: return 11
        case .caption2: return 10
        default: return 15
        }
    }
}
