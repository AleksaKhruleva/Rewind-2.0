import SwiftUI

struct SquareImageModifier: ViewModifier {
    let cornerRadius: CGFloat
    let image: UIImage
    
    public init(cornerRadius: CGFloat, image: UIImage) {
        self.cornerRadius = cornerRadius
        self.image = image
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

public extension View {
    func toSquare(_ image: UIImage, cornerRadius: CGFloat) -> some View {
        self.modifier(SquareImageModifier(cornerRadius: cornerRadius, image: image))
    }
}
