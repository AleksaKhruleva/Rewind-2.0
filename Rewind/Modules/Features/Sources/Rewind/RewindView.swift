import SwiftUI
import UIComponents
import Base
import Domain
import AccessibilitySupport

public struct RewindView: View {
    @State private var viewModel: RewindViewModel
    @State private var filterSettingsShown = false
    @State private var isSelectGroupPresented = false

    @Environment(\.showToast) private var showToast

    public init(router: RewindRouter) {
        viewModel = RewindViewModel(router: router)
    }

    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if !viewModel.groupGallery.isEmpty {
                VStack(spacing: 10) {
                    MediaTopButtons {
                        if let currentGalleryItemId = viewModel.currentGalleryItem?.id {
                            viewModel.router.navigateToMediaDetails(currentGalleryItemId)
                        }
                    } onSettingsTap: {
                        filterSettingsShown = true
                        Task {
                            await viewModel.dispatch(.stopPlayer)
                        }
                    }

                    if viewModel.currentGalleryItem != nil {
                        mediaView
                    } else {
                        DomainAsset.defaultPlaceholder.swiftUIImage
                            .opacity(0)
                            .overlay {
                                RewindNoteTextView(text: "There are no medias for such filters 🫥")
                            }
                    }

                    HStack {
                        author
                        Spacer()
                        RewindRollsStat(rolls: $viewModel.rolls)
                    }
                }
                .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.15))
                .padding(.horizontal, 8)
            } else {
                RewindNoteTextView(text: "This group's gallery is empty 🫥")
            }

            VStack {
                header
                Spacer()
            }

            VStack {
                Spacer()
                GalleryPreview(
                    gallerySize: viewModel.groupGallery.count,
                    imageURLs: viewModel.groupGallery
                        .filter { $0.memory.mediaType != .video }
                        .map { $0.memory.mediaURL }
                )
                .onTapGesture {
                    viewModel.router.navigateToGallery()
                }
            }
            .safeAreaPadding(20)
        }
        .onAppear {
            viewModel.set(showToast: showToast)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isSelectGroupPresented) {
            GroupSelectionView(
                user: viewModel.user,
                groups: viewModel.groups,
                router: viewModel.router,
                onGroupSelected: { newGroup in
                    Task {
                        await viewModel.dispatch(.selectedNewGroup(newGroup))
                    }
                }
            )
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(450)])
        }
        .sheet(isPresented: $filterSettingsShown) {
            FilterView(
                title: UIComponentsStrings.Rewind.Filters.title,
                filters: $viewModel.currentFilters
            ) {
                Task { await viewModel.dispatch(.fetchRandomGalleryItems(.hard)) }
            }
        }
        .onTopAppear {
            Task {
                await viewModel.dispatch(.fetchUser)
                await viewModel.dispatch(.fetchGroups)
                await viewModel.dispatch(.fetchGallery)
                await viewModel.dispatch(.fetchRandomGalleryItems(.soft))
                await viewModel.dispatch(.fetchCurrentMedia)
                await viewModel.dispatch(.loadAvatars)
            }
        }
        .onTopDisappear {
            Task {
                await viewModel.dispatch(.stopPlayer)
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        RewindHeader {
            if viewModel.currentGroupState == .notReady {
                ProgressView()
                    .frame(42)
            } else if let image = viewModel.groupImage {
                RoundImageView(image: image)
                    .contentShape(Circle())
                    .onTapGesture {
                        Task {
                            await viewModel.dispatch(.openGroup)
                        }
                    }
                    .blur(radius: viewModel.userGroupsState == .notReady ? 3 : 0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.userGroupsState)
                    .disabledWithOpacity(viewModel.userGroupsState == .notReady)
            }
        } centerView: {
            HStack {
                groupsButton

                Spacer()

                mapButton
            }
        } rightView: {
            if let userImage = viewModel.userImage {
                RoundImageView(image: userImage)
                    .contentShape(Circle())
                    .onTapGesture {
                        if !viewModel.user.isEmpty {
                            viewModel.router.navigateToAccount(user: viewModel.user)
                        }
                    }.rewindAccessibilityIdentifier(.rewind(.button(.account)))
            } else {
                ProgressView()
                    .frame(42)
            }
        }
    }

    private var groupsButton: some View {
        Button {
            isSelectGroupPresented = true
            Task {
                await viewModel.dispatch(.stopPlayer)
            }
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 17))

                Text(UIComponentsStrings.Rewind.Groups.count(viewModel.groups.count))
                    .modifier(RoundFontModifier(size: 15))

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .black))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(Color.backgroundSecondary)
            .clipShape(Capsule())
        }
        .padding(.horizontal, viewModel.groupImage == nil ? -8 : 0)
        .foregroundStyle(Color.textPrimary)
        .blur(radius: viewModel.userGroupsState == .notReady ? 3 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.userGroupsState)
        .disabledWithOpacity(viewModel.userGroupsState == .notReady)
    }

    private var mapButton: some View {
        Button {
            viewModel.router.navigateToMap(
                galleryItems: viewModel.groupGallery
                    .filter {
                        $0.memory.latitude != nil && $0.memory.longitude != nil &&
                        $0.memory.latitude != 0 && $0.memory.longitude != 0
                    }
            )
        } label: {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color.backgroundSecondary)
                .clipShape(Circle())
        }
        .foregroundStyle(Color.textPrimary)
    }

    @ViewBuilder
    private var mediaView: some View {
        if let currentGalleryItem = viewModel.currentGalleryItem {
            MediaContentView(
                galleryItem: currentGalleryItem,
                onSave: {},
                onLike: { liked in
                    Task {
                        await viewModel.dispatch(liked ? .unlikeMedia : .likeMedia)
                    }
                },
                onToggleSound: {
                    Task {
                        await viewModel.dispatch(.toggleTrackPlaying)
                    }
                },
                isTrackPlaying: $viewModel.isTrackPlaying
            )
            .gesture(
                ExclusiveGesture(
                    TapGesture(),
                    LongPressGesture(minimumDuration: 0.4)
                )
                .onEnded { _ in
                    Task {
                        await viewModel.dispatch(.showNextMediaItem)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var author: some View {
        if let memory = viewModel.currentGalleryItem?.memory {
            HStack {
                AuthorBadgeView(
                    imageURL: memory.userImage,
                    name: memory.username,
                    date: memory.createdAt,
                    track: memory.lightTrack
                )
            }
        }
    }
}

#Preview {
    RewindView(router: RewindRouter(appRouter: AppRouter()))
}
