import SwiftUI

public struct HeaderBadgeView: View {
    private let image: UIImage
    private let imageSize: CGFloat
    private let cornerRadius: CGFloat
    private let text: String
    private let fontSize: CGFloat
    
    public init(image: UIImage, imageSize: CGFloat = 30, cornerRadius: CGFloat = 15, text: String, fontSize: CGFloat = 17) {
        self.image = image
        self.imageSize = imageSize
        self.cornerRadius = cornerRadius
        self.text = text
        self.fontSize = fontSize
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(imageSize)
                .cornerRadius(cornerRadius)
            
            Text(text)
                .modifier(RoundFontModifier(size: fontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    VStack {
        HeaderBadgeView(
            image: UIComponentsAsset.avatar.image,
            text: "flowykk"
        )
        
        HeaderBadgeView(
            image: UIComponentsAsset.avatar.image,
            imageSize: 45,
            cornerRadius: 15,
            text: "flowykk",
            fontSize: 20
        )
    }
}
