import SwiftUI

public struct RoundImageView: View {
    private let image: UIImage
    private let size: CGFloat
    
    public init(image: UIImage, size: CGFloat = 42) {
        self.image = image
        self.size = size
    }
    
    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}
