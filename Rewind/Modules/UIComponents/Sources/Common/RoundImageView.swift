import SwiftUI

public struct RoundImageView: View {
    private let image: UIImage
    private let size: CGFloat
    
    public init(image: UIImage, size: CGFloat) {
        self.image = image
        self.size = size
    }
    
    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}
