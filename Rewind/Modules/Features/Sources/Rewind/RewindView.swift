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
    @Environment(\.isTopScreen) private var isTopScreen

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
            Task {
                await viewModel.dispatch(.fetchUser)
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isSelectGroupPresented) {
            GroupSelectionView(groups: viewModel.groups, router: viewModel.router)
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
                await viewModel.dispatch(.fetchGroups)
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
            if viewModel.currentGroupState == .notReady {
                ProgressView()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
            } else if let image = groupImage {
                RoundImageView(image: image)
                    .contentShape(Circle())
                    .onTapGesture {
                        Task {
                            await viewModel.dispatch(.openGroup)
                        }
                    }
            }
        } centerView: {
            HStack {
                groupsButton

                Spacer()

                mapButton
            }
        } rightView: {
            RoundImageView(image: viewModel.user.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    if !viewModel.user.isEmpty {
                        viewModel.router.navigateToAccount(user: viewModel.user)
                    }
                }
            }.rewindAccessibilityIdentifier(.rewind(.button(.account)))
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
        .padding(.horizontal, groupImage == nil ? -8 : 0)
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
            mediaItem: viewModel.currentMediaItem,
            onSave: {},
            onLike: {},
            onToggleSound: {
                Task {
                    await viewModel.dispatch(.toggleTrackPlaying)
                }
            },
            isTrackPlaying: $viewModel.isTrackPlaying
        )
        .onTapGesture {
            Task {
                await viewModel.dispatch(.showNextMediaItem)
            }
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
