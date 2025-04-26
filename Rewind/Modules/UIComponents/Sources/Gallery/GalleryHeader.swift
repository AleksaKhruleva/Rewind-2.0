import SwiftUI

public struct GalleryHeader: View {
    private let image: UIImage
    private let groupName: String
    private let onAddingQuote: () -> Void
    private let onAddingMedia: () -> Void
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(
        image: UIImage,
        groupName: String,
        onAddingQuote: @escaping () -> Void,
        onAddingMedia: @escaping () -> Void
    ) {
        self.image = image
        self.groupName = groupName
        self.onAddingQuote = onAddingQuote
        self.onAddingMedia = onAddingMedia
    }
    
    public var body: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
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
