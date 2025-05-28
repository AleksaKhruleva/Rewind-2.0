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

            VStack(spacing: 10) {
                MediaTopButtons {
                    viewModel.router.navigateToMediaDetails(viewModel.currentMediaItem)
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
                    print("New group selected, need to update rewind")
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
            FilterView(title: UIComponentsStrings.Rewind.Filters.title) { settings in
                print(settings)
            }
        }
        .onTopAppear {
            Task {
                await viewModel.dispatch(.fetchUser)
                await viewModel.dispatch(.fetchGroups)
                await viewModel.dispatch(.loadAvatars)
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
            viewModel.router.navigateToMap()
        } label: {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color.backgroundSecondary)
                .clipShape(Circle())
        }
        .foregroundStyle(Color.textPrimary)
    }

    private var mediaView: some View {
        MediaContentView(
            galleryItem: viewModel.currentMediaItem,
            onSave: {},
            onLike: { _ in },
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

    private var author: some View {
        HStack {
            AuthorBadgeView(
                imageURL: URL(
                    string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"
                ),
                name: "sasha",
                date: "22.04.2025",
                track: viewModel.currentMediaItem.memory.lightTrack
            )
        }
    }
}

#Preview {
    RewindView(router: RewindRouter(appRouter: AppRouter()))
}
