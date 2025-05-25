// swiftlint:disable identifier_name
import SwiftUI

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xFF0000) >> 16) / 255
            let g = Double((hexNumber & 0x00FF00) >> 8) / 255
            let b = Double(hexNumber & 0x0000FF) / 255

            self.init(red: r, green: g, blue: b)
        } else {
            self.init(red: 1, green: 1, blue: 1)
        }
    }

    static var random: Self {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

public extension Color {
    static let background = UIComponentsAsset.background.swiftUIColor
    static let backgroundInverted = UIComponentsAsset.backgroundInverted.swiftUIColor
    static let backgroundSecondary = UIComponentsAsset.backgroundSecondary.swiftUIColor
    static let iconsBorder = UIComponentsAsset.iconsBorder.swiftUIColor
    static let pinkPrimary = UIComponentsAsset.pinkPrimary.swiftUIColor
    static let pinkPrimaryLight = UIComponentsAsset.pinkPrimaryLight.swiftUIColor
    static let riskyBackground = UIComponentsAsset.riskyBackground.swiftUIColor
    static let riskyPrimary = UIComponentsAsset.riskyPrimary.swiftUIColor
    static let riskySecondary = UIComponentsAsset.riskySecondary.swiftUIColor
    static let textPrimary = UIComponentsAsset.textPrimary.swiftUIColor
    static let textPrimaryInverted = UIComponentsAsset.textPrimaryInverted.swiftUIColor
    static let textSecondary = UIComponentsAsset.textSecondary.swiftUIColor
    static let textTertiary = UIComponentsAsset.textTertiary.swiftUIColor
    static let textTertiaryLight = UIComponentsAsset.textTertiaryLight.swiftUIColor
}
// swiftlint:enable identifier_name
