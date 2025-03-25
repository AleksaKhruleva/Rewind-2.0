import SwiftUI

public struct GalleryMenu<Content: View>: View {
    private let label: Content
    
    public init(
        @ViewBuilder label: () -> Content
    ) {
        self.label = label()
    }
    
    public var body: some View {
        Menu {
            Button {
                // TODO: smth
            } label: {
                Label("Новое фото или видео", systemImage: "photo.fill")
            }
            
            Button {
                // TODO: smth
            } label: {
                Label("Новая цитата", systemImage: "quote.bubble.fill")
            }
        } label: {
            label
        }
    }
}

#Preview {
    GalleryMenu {
        Text("123")
    }
}
