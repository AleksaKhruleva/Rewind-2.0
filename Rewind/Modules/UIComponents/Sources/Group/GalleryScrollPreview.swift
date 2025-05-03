import SwiftUI

public struct GalleryScrollPreview: View {
    private let images: [UIImage]
    
    private static let imageSize: CGFloat = 100
    private static let cornerRadius: CGFloat = 14
    
    public init(images: [UIImage]) {
        self.images = images
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Group.gallery)
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 16)
            
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.backgroundSecondary)
                
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: Self.imageSize, height: Self.imageSize)
                                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                            }
                        }
                    }
                    .frame(height: Self.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                    .padding(.leading, 10)
                    .padding(.trailing, 5)
                    
                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: Self.imageSize)
                        .modifier(RoundFontModifier(size: 14))
                        .padding(.trailing, 6)
                }
            }
            .frame(height: 120)
        }
    }
}
