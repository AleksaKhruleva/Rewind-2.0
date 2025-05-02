import SwiftUI

public struct AvatarView: View {
    private let image: UIImage
    private let text: String
    
    public init(image: UIImage?, text: String) {
        self.image = image ?? UIImage(systemName: "person.fill")!
        self.text = text
    }
    
    public var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 130)
                .cornerRadius(65)
            
            Text(text)
                .foregroundColor(.textPrimary)
                .modifier(RoundFontModifier(size: AccountConstants.avatarTextFontSize, weight: .black))
        }
    }
}

#Preview {
    AvatarView(image: UIImage(named: "avatar"), text: "flowykk")
    AvatarView(
        image: UIComponentsAsset.matthewMcConaughey.image,
        text: "Matthew"
    )
}
