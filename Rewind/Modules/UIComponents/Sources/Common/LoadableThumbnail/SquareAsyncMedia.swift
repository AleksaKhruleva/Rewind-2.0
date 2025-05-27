import SwiftUI
import AVFoundation
import Domain

public struct SquareAsyncMedia: View {
    let url: URL?
    let cornerRadius: CGFloat
    let mediaType: MediaType

    public init(
        url: URL?,
        type: MediaType,
        cornerRadius: CGFloat = 40
    ) {
        self.url = url
        self.mediaType = type
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    switch mediaType {
                    case .image, .quote:
                        LoadableImageThumbnail(url: url, content: contentBuilder)
                    case .video:
                        LoadableVideoThumbnail(url: url, content: contentBuilder)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private func contentBuilder(_ state: LoadableMediaState) -> some View {
        switch state {
        case .empty:
            imageView(for: DomainAsset.defaultPlaceholder.image)
        case .ready(let image):
            imageView(for: image)
        case .failure:
            Color.red.opacity(0.2)
                .overlay(
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                )
        }
    }

    private func imageView(for image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
