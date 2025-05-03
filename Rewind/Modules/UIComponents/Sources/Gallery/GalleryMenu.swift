import SwiftUI

public struct GalleryMenu<Content: View>: View {
    private let label: Content
    private let onAddingQuote: () -> Void
    private let onAddingMedia: () -> Void
    
    public init(
        @ViewBuilder label: () -> Content,
        onAddingQuote: @escaping () -> Void,
        onAddingMedia: @escaping () -> Void
    ) {
        self.label = label()
        self.onAddingQuote = onAddingQuote
        self.onAddingMedia = onAddingMedia
    }
    
    public var body: some View {
        Menu {
            Button {
                onAddingMedia()
            } label: {
                Label(UIComponentsStrings.Gallery.newMedia, systemImage: "photo.fill")
            }
            
            Button {
                onAddingQuote()
            } label: {
                Label(UIComponentsStrings.Gallery.newQuote, systemImage: "quote.bubble.fill")
            }
        } label: {
            label
        }
    }
}
