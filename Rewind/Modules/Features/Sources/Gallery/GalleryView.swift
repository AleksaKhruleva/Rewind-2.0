import SwiftUI
import UIComponents

public struct GalleryView: View {
    @State private var isBlurredMediaPresented = false
    @State private var selectedMedia: UIImage?
    
    let router: GalleryRouter
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(router: GalleryRouter) {
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            GalleryHeader(
                image: UIComponentsAsset.media5.image,
                groupName: "Group name",
                onAddingQuote: router.navigateToQuote,
                onAddingMedia: {
                    // TODO: smth
                }
            )
            
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
            .safeAreaInset(edge: .bottom) {
                ZStack(alignment: .bottom) {
                    footer
                }
            }
            
            Spacer(minLength: 0)
        }
        .overlay {
            if let selectedMedia, isBlurredMediaPresented {
                BlurredMediaView(
                    image: selectedMedia,
                    isPresented: $isBlurredMediaPresented,
                    showMediaDetails: router.navigateToMediaDetails
                )
            }
        }
    }
    
    private var footer: some View {
        ZStack {
            HStack {
                GalleryMenu(
                    label: { RewindMediaButton(size: 50, fontSize: 28, type: .plus) {} },
                    onAddingQuote: router.navigateToQuote,
                    onAddingMedia: {
                        // TODO: smth
                    }
                )
                
                Spacer()
                
                RewindMediaButton(size: 60, fontSize: 28, type: .rewind) { dismiss() }
                
                Spacer()
                
                RewindMediaButton(size: 50, fontSize: 28, type: .settings) {
                    print("plus")
                }
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 20)
            .background {
                BackgroundGradientView(height: 130)
            }
        }
    }
}
