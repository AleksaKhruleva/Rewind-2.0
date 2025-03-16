import SwiftUI

struct InformationTableCell: View {
    private let icon: String
    private let text: String
    private let needChevron: Bool
    private let isRisky: Bool
    private let action: () -> Void
    
    private var foregroundColor: Color {
        isRisky ?
        UIComponentsAsset.riskyTableTextColor.swiftUIColor :
        UIComponentsAsset.primaryColor.swiftUIColor
    }
    
    public init(
        icon: String,
        text: String,
        needChevron: Bool,
        isRisky: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.text = text
        self.needChevron = needChevron
        self.isRisky = isRisky
        self.action = action
    }
    
    var body: some View {
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
        .onTapGesture {
            if needChevron {
                action()
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
