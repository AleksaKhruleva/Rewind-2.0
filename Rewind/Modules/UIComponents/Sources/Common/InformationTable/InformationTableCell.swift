import SwiftUI
import AccessibilitySupport

struct InformationTableCell: View {
    var icon: String
    var text: String
    var needChevron: Bool
    var isRisky: Bool
    var accessibilityElement: RewindElement?
    var action: () -> Void

    var foregroundColor: Color {
        isRisky ? .riskyPrimary : .textPrimary
    }

    var body: some View {
        Button {
            if needChevron {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 30, height: 30)

                Text(text)
                    .modifier(
                        RoundFontModifier(
                            size: AccountConstants.defaultFontSize,
                            weight: .bold,
                            foregroundColor: foregroundColor
                        )
                    )

                Spacer()

                if needChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17))
                        .fontWeight(.bold)
                        .frame(width: 30, height: 30)
                }
            }
            .foregroundColor(foregroundColor)
            .contentShape(Rectangle())
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .ifLet(accessibilityElement) { view, accessibilityElement in
            view.rewindAccessibilityIdentifier(accessibilityElement)
        }
    }
}
