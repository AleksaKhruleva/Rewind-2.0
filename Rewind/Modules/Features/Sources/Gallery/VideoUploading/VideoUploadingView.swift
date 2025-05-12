import AVFoundation
import Combine
import Domain
import SwiftUI
import UIComponents

public struct VideoUploadingView: View {
    @State private var viewModel = VideoUploadingViewModel()
    @State private var timerCancellable: Cancellable?
    
    @Environment(\.showToast)
    private var showToast
    @Environment(\.dismiss)
    private var dismiss
    
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common)
    
    public init(media: LoadedMedia) {
        if case let .video(url, _) = media.content {
            self.viewModel.dispatch(.initializePlayer(AVURLAsset(url: url)))
        }
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
                        
                        musicSection
                        
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
                onCrop: { _,_ in },
                onVideoCrop: { scale, offset in
                    viewModel.dispatch(.applyCrop(scale: scale, offset: offset))
                }
            )
        }
//        .onChange(of: viewModel.toastMessage) { message in
//            guard let message else { return }
//            showToast(message)
//            viewModel.toastMessage = nil
//        }
        .onAppear {
            timerCancellable = timer.connect()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            viewModel.dispatch(.updateTime)
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
    
    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Music.sectionTitle)
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)
            VStack(alignment: .leading, spacing: 5) {
                MembersTableButton(
                    systemImageName: "music.note.list",
                    title: UIComponentsStrings.Music.addMusic,
                    imageSize: 20) {
                        // TODO: show add music view
                    }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
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
            // TODO: save video
        }
    }
    
    private func videoPlayer(player: AVPlayer) -> some View {
        CustomPlayerView(
            isPlaying: $viewModel.isPlaying,
            player: player,
            startTime: viewModel.startTime,
            shouldSeekToStartTime: viewModel.shouldSeekToStartTime,
            onSeekComplete: {
                viewModel.dispatch(.completeSeek)
            }
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .contentShape(RoundedRectangle(cornerRadius: 40))
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
