import SwiftUI

private let imageSize: CGFloat = 100
private let imageCornerRadius: CGFloat = 14

public struct GalleryScrollPreview: View {
    private let images: [UIImage]
    private let onChevronTap: () -> Void

    public init(images: [UIImage], onChevronTap: @escaping () -> Void) {
        self.images = images
        self.onChevronTap = onChevronTap
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
                                    .frame(width: imageSize, height: imageSize)
                                    .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous))
                            }
                        }
                    }
                    .frame(height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous))
                    .padding(.leading, 10)
                    .padding(.trailing, 5)

                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: imageSize)
                        .modifier(RoundFontModifier(size: 14))
                        .padding(.trailing, 6)
                        .onTapGesture {
                            onChevronTap()
                        }
                }
            }
            .frame(height: 120)
        }
    }
}
