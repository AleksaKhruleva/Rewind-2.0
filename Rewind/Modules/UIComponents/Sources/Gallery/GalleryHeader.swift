import SwiftUI

public struct GalleryHeader: View {
    private let image: UIImage
    private let groupName: String
    private let onDismiss: () -> Void
    private let onAddingQuote: () -> Void
    private let onAddingMedias: () -> Void

    public init(
        image: UIImage,
        groupName: String,
        onDismiss: @escaping () -> Void,
        onAddingQuote: @escaping () -> Void,
        onAddingMedias: @escaping () -> Void
    ) {
        self.image = image
        self.groupName = groupName
        self.onDismiss = onDismiss
        self.onAddingQuote = onAddingQuote
        self.onAddingMedias = onAddingMedias
    }

    public var body: some View {
        RewindHeader {
            RewindButton(type: .xmark) { onDismiss() }
        } centerView: {
            HeaderBadgeView(
                image: image,
                text: groupName
            )
        } rightView: {
            GalleryMenu(
                label: { RewindButton(type: .plus) {} },
                onAddingQuote: onAddingQuote,
                onAddingMedias: onAddingMedias
            )
        }
    }
}
