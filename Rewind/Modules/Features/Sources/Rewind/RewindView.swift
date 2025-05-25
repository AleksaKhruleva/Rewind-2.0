import SwiftUI
import UIComponents
import Base
import Domain

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
            viewModel.dispatch(.fetchUser)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isSelectGroupPresented) {
            SelectGroupView()
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

    private var header: some View {
        RewindHeader {
            RoundImageView(image: UIComponentsAsset.media5.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    router.navigateToGroup()
                }
        } centerView: {
            GroupsAndLocationHeader(groupCount: 8) {
                isSelectGroupPresented = true
            } onGlobeTap: {
                router.navigateToMap()
            }
        } rightView: {
            RoundImageView(image: viewModel.user.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    if !viewModel.user.isEmpty {
                        router.navigateToAccount(user: viewModel.user)
                    }
                }
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
