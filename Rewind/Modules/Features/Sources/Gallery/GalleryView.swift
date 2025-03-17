import SwiftUI
import UIComponents

public struct GalleryView: View {
    @State private var isBlurredMediaPresented = false
    @State private var selectedMedia: UIImage?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            GalleryHeader(image: UIComponentsAsset.media5.image, groupName: "Group name")
            
            ScrollView {
                VStack {
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
                                    withAnimation {
                                        selectedMedia = media
                                        isBlurredMediaPresented = true
                                    }
                                }
                        }
                    }
                    
                    RewindNoteTextView(text: "🙀  The end")
                        .padding(.vertical, 4)
                }
            }
            .scrollIndicators(.hidden)
            
            Spacer(minLength: 0)
        }
        .overlay {
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
    GalleryView()
}
