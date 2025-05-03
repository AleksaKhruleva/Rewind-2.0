import SwiftUI

public struct GalleryPreview: View {
    private let gallerySize: Int
    private let images: [UIImage]
    
    public init(gallerySize: Int, images: [UIImage]) {
        self.gallerySize = gallerySize
        self.images = images
    }
    
    public var body: some View {
        VStack(spacing: 5) {
            Text(UIComponentsStrings.Gallery.Media.count(gallerySize))
                .modifier(RoundFontModifier(size: 17))
            
            if !images.isEmpty {
                HStack(spacing: -8) {
                    ForEach(Array(images.prefix(4).enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .rotationEffect(rotation(for: images.count, at: index))
                            .offset(y: verticalOffset(for: images.count, at: index))
                            .zIndex(Double(index))
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func rotation(for count: Int, at index: Int) -> Angle {
        switch count {
        case 1:
            return .zero
        case 2:
            return index == 0 ? .degrees(-8) : .degrees(8)
        case 3:
            return [.degrees(-10), .zero, .degrees(10)][index]
        case 4:
            return [.degrees(-15), .degrees(-5), .degrees(5), .degrees(15)][index]
        default:
            return .zero
        }
    }
    
    private func verticalOffset(for count: Int, at index: Int) -> CGFloat {
        switch count {
        case 3:
            return [4, 0, 4][index]
        case 4:
            return [10, 4, 4, 10][index]
        default:
            return 0
        }
    }
}

#Preview {
    let images = [
        UIComponentsAsset.media1.image,
        UIComponentsAsset.media2.image,
        UIComponentsAsset.media3.image,
        UIComponentsAsset.media4.image
    ]
    
    VStack {
        GalleryPreview(gallerySize: 0, images: Array(images.prefix(0)))
        GalleryPreview(gallerySize: 1, images: Array(images.prefix(1)))
        GalleryPreview(gallerySize: 2, images: Array(images.prefix(2)))
        GalleryPreview(gallerySize: 3, images: Array(images.prefix(3)))
        GalleryPreview(gallerySize: 56, images: Array(images.prefix(4)))
    }
}
