import SwiftUI
import UIComponents
import PhotosUI
import Domain

public struct MediasUploadingView: View {
    @State private var viewModel: MediasUploadingViewModel

    private let router: MediasUploadingRouter

    @Environment(\.showToast)
    private var showToast

    public init(router: MediasUploadingRouter) {
        viewModel = .init()
        self.router = router
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.loadedMedias) { loadedMedia in
                            loadedMedia.makeView()
                                .overlay {
                                    badges(for: loadedMedia) {
                                        Task {
                                            await viewModel.dispatch(.removeMedia(loadedMedia))
                                        }
                                    }
                                }
                                .onTapGesture {
                                    Task {
                                        await viewModel.dispatch(.showMediaSettings(loadedMedia))
                                    }
                                }
                        }

                        photosPicker
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.vertical, 10)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .background(Color.backgroundSecondary)
                .cornerRadius(32)
                .padding(.bottom, 8)

                settingsToggle
                    .padding(.bottom, 16)

                TagsSectionView(tags: $viewModel.tags)
                    .disabledWithOpacity(!viewModel.similarSettigns)

                Spacer()
            }
            .navigationDestination(item: $viewModel.viewingMedia) { media in
                mediaSettings(for: media)
            }
            .onAppear {
                viewModel.set(showToast: showToast)
            }
            .padding(.horizontal, 8)
            .background(Color.background)
            .onChange(of: viewModel.selection) { _, newItems in
                Task {
                    await viewModel.dispatch(.importMedias(newItems))
                }
            }
            .safeAreaInset(edge: .bottom) {
                continueButton
            }
        }
    }

    private var header: some View {
        RewindHeader(leftView: {
            RewindButton(type: .leftChevron) { router.dismiss() }
        })
    }

    private var settingsToggle: some View {
        Toggle(isOn: $viewModel.similarSettigns) {
            Text("Similar settings for all media")
                .modifier(RoundFontModifier(size: 17, weight: .bold, foregroundColor: .textPrimary))
        }
        .toggleStyle(SwitchToggleStyle(tint: .pinkPrimaryLight))
        .disabledWithOpacity(viewModel.toggleDisabled)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(25)
    }

    private var photosPicker: some View {
        PhotosPicker(
            selection: $viewModel.selection
        ) {
            RoundedRectangle(cornerRadius: 25)
                .frame(140)
                .foregroundColor(Color.background)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.textTertiary)
                }
        }
    }

    private func mediaSettings(for media: LoadedMedia) -> some View {
        Group {
            switch media.content {
            case .image:
                ImageUploadingView(media: media) { newMedia in
                    if let index = viewModel.loadedMedias.firstIndex(where: { $0.id == newMedia.id }) {
                        viewModel.loadedMedias[index] = newMedia
                    }
                    if let tags = newMedia.tags, !tags.isEmpty {
                        viewModel.toggleDisabled = true
                        viewModel.similarSettigns = false
                    } else {
                        viewModel.toggleDisabled = false
                    }
                }
            case .video:
                VideoUploadingView(media: media) { newMedia in
                    if let index = viewModel.loadedMedias.firstIndex(where: { $0.id == newMedia.id }) {
                        viewModel.loadedMedias[index] = newMedia
                    }
                    if let tags = newMedia.tags, !tags.isEmpty {
                        viewModel.toggleDisabled = true
                        viewModel.similarSettigns = false
                    } else {
                        viewModel.toggleDisabled = false
                    }
                }
            }
        }.toolbar(.hidden)
    }

    private func badges(
        for item: LoadedMedia,
        onRemove: @escaping () -> Void
    ) -> some View {
        return VStack {
            HStack {
                if case .video = item.content {
                    badgeItem(icon: "video.fill")
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    onRemove()
                } label: {
                    badgeItem(icon: "xmark")
                        .foregroundColor(.white)
                }
            }

            Spacer()
        }.padding(8)

        func badgeItem(icon: String) -> some View {
            RoundedRectangle(cornerRadius: 13)
                .fill(.ultraThinMaterial)
                .frame(34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .black))
                }
        }
    }

    private var continueButton: some View {
        GradientButton(title: "Save memories", width: .given(200)) {
            Task {
                await viewModel.dispatch(.createMedias)
                router.dismiss()
            }
        }.disabledWithOpacity(viewModel.loadedMedias.isEmpty)
    }
}

extension LoadedMedia {
    @MainActor
    func makeView() -> some View {
        Group {
            switch self.content {
            case let .image(image):
                Image(uiImage: image).resizable()
            case let .video(_, firstFrame):
                Image(uiImage: firstFrame).resizable()
            }
        }
        .scaledToFill()
        .frame(140)
        .cornerRadius(25)
    }
}
