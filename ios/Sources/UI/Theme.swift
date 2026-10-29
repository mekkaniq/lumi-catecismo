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

/// Cores comuns do app (claro e escuro).
enum Pal {
    static let bg = Color(light: 0xf5f6f2, dark: 0x0f1712)
    static let surface = Color(light: 0xffffff, dark: 0x17221b)
    static let fg = Color(light: 0x1d2420, dark: 0xe8eee9)
    static let muted = Color(light: 0x5f6862, dark: 0x9aa79f)
    static let line = Color(light: 0xd9ded8, dark: 0x2a3a30)
    static let gold = Color(light: 0xc6912c, dark: 0xe0ad4a)
    static let ok = Color(light: 0x2f7d4a, dark: 0x6cc48a)
    static let okBg = Color(light: 0xe2f1e6, dark: 0x1b3324)
    static let bad = Color(light: 0xb4472e, dark: 0xec8a72)
    static let badBg = Color(light: 0xf8e6e0, dark: 0x3a201a)
    static let bubble = Color(light: 0xffffff, dark: 0x22382b)
    static let cream = Color(hex: 0xf6ecd6)
    static let brightGold = Color(hex: 0xe7b552)
}

/// Cores de cada livro (verde da IPB, vinho e azul-petróleo).
struct Theme {
    let accent: Color
    let primary: Color
    let deep: Color
    let soft: Color
    let glow: [Color]
    let spine: Color

    static func of(_ id: String) -> Theme {
        switch id {
        case "maior": return .maior
        case "conf": return .conf
        default: return .breve
        }
    }

    static let breve = Theme(
        accent: Color(light: 0x215732, dark: 0x6dbb89),
        primary: Color(light: 0x215732, dark: 0x2c7a4b),
        deep: Color(light: 0x123d26, dark: 0x0c2418),
        soft: Color(light: 0xe3ede6, dark: 0x1c3226),
        glow: [Color(hex: 0x0b2619), Color(hex: 0x2a6b45), Color(hex: 0xe7b552)],
        spine: Color(hex: 0x215732))

    static let maior = Theme(
        accent: Color(light: 0x7b2d35, dark: 0xe3949b),
        primary: Color(light: 0x7b2d35, dark: 0x94404a),
        deep: Color(light: 0x3f161b, dark: 0x2a0e12),
        soft: Color(light: 0xf4e7e8, dark: 0x33191c),
        glow: [Color(hex: 0x24090e), Color(hex: 0x83303a), Color(hex: 0xe7b552)],
        spine: Color(hex: 0x7b2d35))

    static let conf = Theme(
        accent: Color(light: 0x1f5068, dark: 0x86c0da),
        primary: Color(light: 0x1f5068, dark: 0x2c6a88),
        deep: Color(light: 0x102c3a, dark: 0x0a1d27),
        soft: Color(light: 0xe3edf2, dark: 0x15303d),
        glow: [Color(hex: 0x08202c), Color(hex: 0x26627f), Color(hex: 0xecc56e)],
        spine: Color(hex: 0x1f5068))
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
    static func display(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif).weight(.bold)
    }
}
