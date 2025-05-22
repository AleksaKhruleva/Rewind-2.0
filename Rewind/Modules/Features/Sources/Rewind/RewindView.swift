import SwiftUI
import UIComponents
import Base
import Domain
import AccessibilitySupport

public struct RewindView: View {
    @State private var viewModel: RewindViewModel
    @State private var filterSettingsShown = false
    @State private var isSelectGroupPresented = false
    
    private let router: RewindRouter
    
    @Environment(\.showToast)
    private var showToast
    
    public init(router: RewindRouter) {
        self.router = router
        viewModel = RewindViewModel()
    }
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 10) {
                MediaTopButtons {
                    router.navigateToMediaDetails(viewModel.currentMediaItem)
                } onSettingsTap: {
                    filterSettingsShown = true
                }
                
                mediaView
                
                HStack {
                    author
                    Spacer()
                    RewindRollsStat(rolls: $viewModel.rolls)
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
        .onAppear {
            viewModel.set(showToast: showToast)
            Task { await viewModel.dispatch(.fetchUser) }
                .task {
                    await viewModel.dispatch(.fetchGroups)
                }
                .ignoresSafeArea(.keyboard)
                .sheet(isPresented: $isSelectGroupPresented) {
                    GroupSelectionView(router: router)
                        .presentationCornerRadius(30)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.height(450)])
                }
                .sheet(isPresented: $filterSettingsShown) {
                    FilterView(title: UIComponentsStrings.Rewind.Filters.title) { settings in
                        print(settings)
                    }
                }
        }
    }
    
    private var groupImage: UIImage? {
        guard let currentGroup = GroupStorage.currentGroup else { return nil }
        
        guard let data = currentGroup.imageData, let image = UIImage(data: data) else {
            return DomainAsset.groupPlaceholder.image
        }
        
        return image
    }
    
    @ViewBuilder
    private var header: some View {
        RewindHeader {
            if let image = groupImage {
                RoundImageView(image: image)
                    .contentShape(Circle())
                    .onTapGesture {
                        // router.navigateToGroup()
                    }
            }
        } centerView: {
            GroupsAndLocationHeader(groupCount: viewModel.groups.count) {
                isSelectGroupPresented = true
            } onGlobeTap: {
                router.navigateToMap()
            }
            .padding(.leading, groupImage == nil ? -8 : 0)
            .animation(.easeInOut, value: viewModel.groups.count)
        } rightView: {
            Button {
                if !viewModel.user.isEmpty {
                    router.navigateToAccount(user: viewModel.user)
                }
            } label: {
                RoundImageView(image: viewModel.user.image, size: 44)
                    .contentShape(Circle())
            }.rewindAccessibilityIdentifier(.rewind(.button(.account)))
        }
    }

    private var mediaView: some View {
        MediaContentView(
            mediaItem: viewModel.currentMediaItem,
            onSave: {},
            onLike: {},
            onToggleSound: {
                viewModel.dispatch(.toggleTrackPlaying)
            },
            isTrackPlaying: $viewModel.isTrackPlaying
        )
        .onTapGesture {
            viewModel.dispatch(.showNextMediaItem)
        }
    }
    
    private var author: some View {
        HStack {
            AuthorBadgeView(
                image: UIComponentsAsset.sasha.image,
                name: "sasha",
                date: "22.04.2025",
                track: viewModel.currentMediaItem.track
            )
        }
    }
}

#Preview {
    RewindView(router: RewindRouter(appRouter: AppRouter()))
}
