import SwiftUI
import UIComponents

public struct RewindView: View {
    @State private var rolls = 0
    @State private var currentIndex = 0
    @State private var isSelectGroupPresented = false
    
    var router: RewindRouter
    
    @Environment(\.showToast)
    private var showToast
    
    public init(router: RewindRouter) {
        self.router = router
    }
    
    // Временно, пока не появится ViewModel
    private let mediaImages: [UIImage] = [
        UIComponentsAsset.media21.image,
        UIComponentsAsset.media1.image,
        UIComponentsAsset.media2.image,
        UIComponentsAsset.media3.image,
        UIComponentsAsset.media4.image,
        UIComponentsAsset.media5.image,
        UIComponentsAsset.media14.image,
        UIComponentsAsset.media15.image,
        UIComponentsAsset.media16.image,
    ]
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                MediaTopButtons {
                    router.navigateToMediaDetails(mediaImages[currentIndex])
                } onSettingsTap: {
                    // TODO: open settings
                }
                
                mediaView
                
                HStack {
                    author
                    Spacer()
                    RewindRollsStat(rolls: $rolls)
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.15))
            .padding(.horizontal, 8)
            
            VStack {
                header
                Spacer()
            }
            
            VStack {
                Spacer()
                GalleryPreview(
                    gallerySize: 63,
                    images: [
                        // Временно
                        UIComponentsAsset.media1.image,
                        UIComponentsAsset.media2.image,
                        UIComponentsAsset.media3.image,
                        UIComponentsAsset.media4.image
                    ]
                )
                .onTapGesture {
                    router.navigateToGallery()
                }
            }
            .safeAreaPadding(20)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isSelectGroupPresented) {
            SelectGroupView()
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
                .presentationDetents([.height(450)])
        }
    }
    
    private var header: some View {
        RewindHeader {
            RoundImageView(image: UIComponentsAsset.media5.image, size: 44)
        } centerView: {
            GroupsAndLocationHeader(groupCount: 8) {
                isSelectGroupPresented = true
            } onGlobeTap: {
                // TODO: show map
            }
        } rightView: {
            RoundImageView(image: UIComponentsAsset.avatar.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    router.navigateToAccount()
                }
        }
    }
    
    private var mediaView: some View {
        Rectangle()
            .toSquare(mediaImages[currentIndex % mediaImages.count], cornerRadius: 40)
            .onTapGesture {
                withAnimation {
                    rolls += 1
                    currentIndex = (currentIndex + 1) % mediaImages.count
                }
            }
            .overlay {
                RewindMediaButtonsOverlay {
                    // TODO: like action
                } saveAction: {
                    saveImageWithToast(image: mediaImages[currentIndex]) { message in
                        showToast(message)
                    }
                }
            }
    }
    
    private var author: some View {
        HStack {
            AuthorBadgeView(
                image: UIComponentsAsset.sasha.image,
                name: "sasha",
                date: "22.04.2025"
            )
        }
    }
}
