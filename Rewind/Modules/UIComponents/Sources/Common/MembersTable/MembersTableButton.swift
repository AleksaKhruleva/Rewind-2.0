import SwiftUI

public struct MembersTableButton: View {
    private let systemImageName: String
    private let title: String
    private let imageSize: CGFloat
    private let action: () -> Void
    
    public init(
        systemImageName: String,
        title: String,
        imageSize: CGFloat,
        action: @escaping () -> Void
    ) {
        self.systemImageName = systemImageName
        self.title = title
        self.imageSize = imageSize
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImageName)
                    .modifier(RoundFontModifier(size: imageSize))
                    .frame(width: 34, height: 34)
                
                Text(title)
                    .modifier(RoundFontModifier(size: 16, foregroundColor: UIComponentsAsset.textPrimary.swiftUIColor))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .modifier(RoundFontModifier(size: 14))
                    .padding(.trailing, 3)
            }
            .frame(height: 35)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
        }
    }
}

#Preview {
    MembersTableButton(
        systemImageName: "person.fill.badge.plus",
        title: "Add member",
        imageSize: 25
    ) {
        print("Add members plz")
    }
    
    MembersTableButton(
        systemImageName: "eye.fill",
        title: "7 members",
        imageSize: 20
    ) {
        print("Show all members")
    }
}
