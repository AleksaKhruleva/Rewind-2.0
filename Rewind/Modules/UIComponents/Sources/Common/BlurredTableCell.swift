import SwiftUI

public struct BlurredTableCell: View {
    private var icon: String
    private var title: String
    private var needChevron: Bool
    private var isRisky: Bool
    private var action: () -> Void = {}
    
    private var foregroundColor: Color {
        isRisky ? .riskyPrimary : .textPrimary
    }
    
    public init(
        icon: String,
        title: String,
        needChevron: Bool = false,
        isRisky: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.needChevron = needChevron
        self.isRisky = isRisky
        self.action = action
    }
        
    public var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 25, height: 25)
            
            Text(title)
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        weight: .bold,
                        foregroundColor: foregroundColor
                    )
                )
            
            if needChevron {
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: AccountConstants.defaultFontSize, weight: .bold))
                    
            }
        }
        .foregroundColor(foregroundColor)
        .onTapGesture {
            action()
        }
        .padding(.horizontal, needChevron ? 24 : 0)
        .padding(.vertical, 16)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea(edges: .all)
        
        VStack(spacing: -8) {
            BlurredTableCell(
                icon: "photo",
                title: "Set new image",
                action: {
                    // TODO: smth
                }
            )
            
            BlurredTableCell(
                icon: "square.and.arrow.down.fill",
                title: "Save Image",
                needChevron: true,
                action: {
                    // TODO: smth
                }
            )
            
            BlurredTableCell(
                icon: "photo",
                title: "Set new image",
                needChevron: true,
                isRisky: true,
                action: {
                    // TODO: smth
                }
            )
        }
        .frame(width: 380)
        .background(.white)
        .cornerRadius(18)
    }
}
