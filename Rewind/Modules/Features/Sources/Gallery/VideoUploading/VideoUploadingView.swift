import AVFoundation
import Combine
import Domain
import SwiftUI
import UIComponents

public struct VideoUploadingView: View {
    @State private var viewModel: VideoUploadingViewModel

    @Environment(\.showToast)
    private var showToast
    @Environment(\.dismiss)
    private var dismiss

    private var onSave: (LoadedMedia) -> Void

    public init(media: LoadedMedia, onSave: @escaping (LoadedMedia) -> Void) {
        self.onSave = onSave
        viewModel = VideoUploadingViewModel(loadedMedia: media)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if let player = viewModel.player {
                        videoPlayer(player: player)

                        if let asset = viewModel.videoAsset {
                            videoTimeline(asset: asset)
                        }

                        tagsSection
                    } else {
                        emptyVideoContent
                            .onTapGesture {
                                viewModel.dispatch(.viewGallery)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .safeAreaInset(edge: .bottom) {
            if viewModel.player != nil {
                continueButton
            }
        }
        .sheet(isPresented: $viewModel.videoPickerPresented) {
            VideoPicker { asset in
                viewModel.dispatch(.selectVideoInGallery(asset))
            }
        }
        .fullScreenCover(item: $viewModel.cropPreviewImage) { identifiable in
            RewindImageEditor(
                image: identifiable.image,
                cropType: .rectangle,
                onCrop: { _, _ in },
                onVideoCrop: { scale, offset in
                    viewModel.dispatch(.applyCrop(scale: scale, offset: offset))
                }
            )
        }
        .onChange(of: viewModel.isSettingsSaved) {
            guard let loadedMedia = viewModel.loadedMedia else { return }
            onSave(loadedMedia)
            dismiss()
        }
        .background(Color.background)
    }

    private var trimStartBinding: Binding<TimeInterval> {
        Binding(
            get: { viewModel.trimStartAsSeconds },
            set: { viewModel.trimStartAsSeconds = $0 }
        )
    }

    private var trimEndBinding: Binding<TimeInterval> {
        Binding(
            get: { viewModel.trimEndAsSeconds },
            set: { viewModel.trimEndAsSeconds = $0 }
        )
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } rightView: {
            if viewModel.player != nil {
                HStack {
                    RewindButton(type: .selectVideo) {
                        viewModel.dispatch(.viewGallery)
                    }
                    RewindButton(type: .crop) {
                        viewModel.dispatch(.cropVideo)
                    }
                }
            }
        }
    }

    private var emptyVideoContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.backgroundSecondary)
                .aspectRatio(1, contentMode: .fit)

            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 130))
                    .foregroundColor(.textSecondary)

                Text(UIComponentsStrings.Video.hint)
                    .modifier(RoundFontModifier(size: 15, weight: .bold))
            }
        }
    }

    private var tagsSection: some View {
        TagsSectionView(tags: $viewModel.tags)
    }

    private var continueButton: some View {
        GradientButton(
            title: UIComponentsStrings.Video.save,
            width: .given(200)
        ) {
            viewModel.dispatch(.saveSettings)
        }
    }

    private func videoPlayer(player: AVPlayer) -> some View {
        CustomPlayerView(
            isPlaying: $viewModel.isPlaying,
            isMuted: $viewModel.isMuted,
            shouldSeekToStartTime: $viewModel.shouldSeekToStartTime,
            player: player,
            startTime: viewModel.startTime,
            onSeekComplete: {
                viewModel.dispatch(.completeSeek)
            }
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .contentShape(RoundedRectangle(cornerRadius: 40))
        .id(viewModel.timelineID)
    }

    private func videoTimeline(asset: AVURLAsset) -> some View {
        VideoTimelineView(
            currentTime: $viewModel.currentTime,
            trimStart: trimStartBinding,
            trimEnd: trimEndBinding,
            asset: asset,
            frameCount: VideoUploadingViewModel.frameCount,
            duration: viewModel.duration,
            onTrimChanged: {
                viewModel.dispatch(.changeTrim)
            }
        )
        .frame(height: UIScreen.main.bounds.width / CGFloat(VideoUploadingViewModel.frameCount))
        .id(viewModel.timelineID)
    }
}
