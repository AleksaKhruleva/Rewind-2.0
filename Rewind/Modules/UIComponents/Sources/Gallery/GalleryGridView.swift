import SwiftUI

public struct GalleryGridView: View {
    @State private var isBlurredMediaPresented = false
    @State private var selectedMedia: UIImage?
    
    public init() {}

    public var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 3) {
                    let medias = GalleryConstants.galleryMedias
                    ForEach(medias, id: \.self) { media in
                        Image(uiImage: media)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .modifier(GalleryItemModifier())
                            .onTapGesture {
                                selectedMedia = media
                                isBlurredMediaPresented = true
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            if let selectedMedia, isBlurredMediaPresented {
                BlurredMediaView(
                    image: selectedMedia,
                    isPresented: $isBlurredMediaPresented
                )
            }
        }
    }
}

#Preview {
    GalleryGridView()
}
