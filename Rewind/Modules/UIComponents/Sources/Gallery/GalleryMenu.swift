import SwiftUI

public struct GalleryMenu<Content: View>: View {
    private let label: Content
    private let onAddingQuote: () -> Void
    private let onAddingMedias: () -> Void
    
    public init(
        @ViewBuilder label: () -> Content,
        onAddingQuote: @escaping () -> Void,
        onAddingMedias: @escaping () -> Void
    ) {
        self.label = label()
        self.onAddingQuote = onAddingQuote
        self.onAddingMedias = onAddingMedias
    }
    
    public var body: some View {
        Menu {
            Button {
                onAddingQuote()
            } label: {
                Label(UIComponentsStrings.Gallery.newQuote, systemImage: "quote.bubble.fill")
            }
            
            Button {
                onAddingMedias()
            } label: {
                Label(UIComponentsStrings.Gallery.newMedia, systemImage: "photo.stack.fill")
            }
        } label: {
            label
        }
    }
}
