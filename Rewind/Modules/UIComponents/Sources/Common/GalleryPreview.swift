import SwiftUI

public struct GalleryPreview: View {
    private let gallerySize: Int
    private let imageURLs: [URL?]

    public init(gallerySize: Int, imageURLs: [URL?]) {
        self.gallerySize = gallerySize
        self.imageURLs = Array(imageURLs.prefix(4))
    }

    public var body: some View {
        VStack(spacing: 5) {
            Text(UIComponentsStrings.Gallery.Media.count(gallerySize))
                .modifier(RoundFontModifier(size: 17))

            if !imageURLs.isEmpty {
                HStack(spacing: -8) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                        SquareAsyncMedia(url: imageURL, type: .image, cornerRadius: 12)
                            .frame(40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.background, lineWidth: 2)
                            )
                            .rotationEffect(rotation(for: imageURLs.count, at: index))
                            .offset(y: verticalOffset(for: imageURLs.count, at: index))
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
