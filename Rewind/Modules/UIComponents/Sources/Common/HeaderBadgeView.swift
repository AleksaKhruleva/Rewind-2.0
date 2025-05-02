import SwiftUI

public struct HeaderBadgeView: View {
    private let image: UIImage
    private let text: String
    
    public init(image: UIImage, text: String) {
        self.image = image
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .cornerRadius(20)
            
            Text(text)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    HeaderBadgeView(
        image: UIComponentsAsset.avatar.image,
        text: "flowykk"
    )
}
