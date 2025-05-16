import SwiftUI

public struct GalleryHeader: View {
    private let image: UIImage
    private let groupName: String
    private let onDismiss: () -> Void
    private let onAddingQuote: () -> Void
    private let onAddingMedia: () -> Void
    
    public init(
        image: UIImage,
        groupName: String,
        onDismiss: @escaping () -> Void,
        onAddingQuote: @escaping () -> Void,
        onAddingMedia: @escaping () -> Void
    ) {
        self.image = image
        self.groupName = groupName
        self.onDismiss = onDismiss
        self.onAddingQuote = onAddingQuote
        self.onAddingMedia = onAddingMedia
    }
    
    public var body: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { onDismiss() }
        } centerView: {
            HeaderBadgeView(
                image: image,
                text: groupName
            )
        } rightView: {
            GalleryMenu(
                label: { RewindButton(type: .plus) {} },
                onAddingQuote: onAddingQuote,
                onAddingMedia: onAddingMedia
            )
        }
    }
}
