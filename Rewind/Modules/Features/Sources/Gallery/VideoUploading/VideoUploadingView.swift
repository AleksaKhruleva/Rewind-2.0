import SwiftUI
import UIComponents
import AVKit
import PhotosUI
import AVFoundation
import Photos

private let maxVideoDuration: CMTime = CMTime(seconds: 15, preferredTimescale: 600)
private let frameCount = 11
private let timelineUpdateInterval = 0.05

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

public struct VideoUploadingView: View {
    @State private var isShowingPicker = false
    @State private var player: AVPlayer?
    @State private var videoAsset: AVURLAsset?
    @State private var isPlaying = false
    
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var timelineID = UUID()
    
    @State private var startTime: CMTime = .zero
    @State private var endTime: CMTime = .zero
    @State private var shouldSeekToStartTime = false
    
    @State private var cropPreviewImage: IdentifiableImage?
    
    @State private var cropScale: CGFloat = 1.0
    @State private var cropOffset: CGSize = .zero
    
    @State private var playerItem: AVPlayerItem?
    
    public init() {}
    
    public var body: some View {
        VStack {
            if let player {
                VStack(spacing: 8) {
                    videoPlayer(player: player)
                    
                    if let asset = videoAsset {
                        videoTimeline(asset: asset)
                    }
                    
                    Rectangle().fill(.clear).frame(height: 1)
                    
                    Button("Choose another video") {
                        isPlaying = false
                        isShowingPicker = true
                    }
                    .modifier(RoundFontModifier(size: 15))
                    
                    Button("Crop video") {
                        isPlaying = false
                        generateCurrentFrameImage()
                    }
                    .modifier(RoundFontModifier(size: 15))
                }
            } else {
                emptyVideoContent
                    .onTapGesture {
                        isShowingPicker = true
                    }
            }
        }
        .padding(.horizontal, 8)
        .sheet(isPresented: $isShowingPicker) {
            VideoPicker { asset in
                resetPlayer()
                loadVideoAsset(from: asset)
            }
        }
        .fullScreenCover(item: $cropPreviewImage) { identifiable in
            RewindImageEditor(
                image: .constant(identifiable.image),
                cropType: .rectangle,
                onCrop: { _,_ in },
                onVideoCrop: { scale, offset in
                    self.cropScale = scale
                    self.cropOffset = offset
                    Task {
                        await applyCropToCurrentVideo()
                    }
                }
            )
        }
        .onReceive(
            Timer.publish(every: timelineUpdateInterval, on: .main, in: .common).autoconnect()
        ) { _ in
            updateCurrentTime()
        }
    }
    
    private var emptyVideoContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.backgroundSecondary)
                .aspectRatio(1, contentMode: .fit)
            
            VStack {
                Image(systemName: "plus")
                    .modifier(RoundFontModifier(size: 80, foregroundColor: .textSecondary))
                
                Text(UIComponentsStrings.Video.hint)
                    .modifier(RoundFontModifier(size: 15, weight: .bold))
            }
        }
    }
    
    private var trimStartBinding: Binding<TimeInterval> {
        Binding(
            get: { startTime.seconds },
            set: { startTime = CMTime(seconds: $0, preferredTimescale: 600) }
        )
    }
    
    private var trimEndBinding: Binding<TimeInterval> {
        Binding(
            get: { endTime.seconds },
            set: { endTime = CMTime(seconds: $0, preferredTimescale: 600) }
        )
    }
    
    private func videoPlayer(player: AVPlayer) -> some View {
        CustomPlayerView(
            isPlaying: $isPlaying,
            player: player,
            startTime: startTime,
            shouldSeekToStartTime: shouldSeekToStartTime,
            onSeekComplete: {
                shouldSeekToStartTime = false
                syncCurrentTime()
            }
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .contentShape(RoundedRectangle(cornerRadius: 40))
    }
    
    private func videoTimeline(asset: AVURLAsset) -> some View {
        VideoTimelineView(
            currentTime: $currentTime,
            trimStart: trimStartBinding,
            trimEnd: trimEndBinding,
            asset: asset,
            frameCount: frameCount,
            duration: duration,
            onTrimChanged: {
                isPlaying = false
                shouldSeekToStartTime = true
            }
        )
        .frame(height: UIScreen.main.bounds.width / CGFloat(frameCount))
        .id(timelineID)
    }
    
    private func syncCurrentTime() {
        currentTime = startTime.seconds
    }
    
    private func updateCurrentTime() {
        guard let player = player, isPlaying else { return }
        currentTime = max(0, player.currentTime().seconds)
        duration = player.currentItem?.duration.seconds ?? 1
        
        if player.currentTime().seconds >= endTime.seconds - 0.05 {
            handleVideoEnd()
        }
    }
    
    private func handleVideoEnd() {
        guard let player = player else { return }
        player.pause()
        player.seek(to: startTime)
        isPlaying = false
    }
    
    private func resetPlayer() {
        if let player = player {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        videoAsset = nil
        self.player = nil
        isPlaying = false
    }
    
    @MainActor
    private func loadVideoAsset(from asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else { return }

            Task { @MainActor in
                do {
                    let videoDuration = try await urlAsset.load(.duration)
                    let clampedDuration = CMTimeMinimum(videoDuration, maxVideoDuration)

                    self.videoAsset = urlAsset
                    self.timelineID = UUID()
                    self.currentTime = 0
                    self.startTime = .zero
                    self.endTime = clampedDuration
                    self.duration = CMTimeGetSeconds(videoDuration)

                    // ✅ создаём AVPlayerItem вручную
                    let item = AVPlayerItem(asset: urlAsset)
                    self.playerItem = item // <-- предполагаем, что у тебя есть @State var playerItem

                    // ✅ создаём AVPlayer с этим item
                    let newPlayer = AVPlayer(playerItem: item)
                    await newPlayer.seek(to: .zero)
                    self.player = newPlayer
                    self.isPlaying = false

                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: item,
                        queue: .main
                    ) { _ in
                        newPlayer.seek(to: self.startTime)
                        self.isPlaying = false
                    }
                } catch {
                    print("Failed to load video: \(error)")
                }
            }
        }
    }
    
    private func generateCurrentFrameImage() {
        guard let asset = videoAsset else { return }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1080, height: 1080)
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        let time = player?.currentTime() ?? startTime
        
        Task {
            do {
                let cgImage: CGImage? = try await withCheckedThrowingContinuation { continuation in
                    generator.generateCGImageAsynchronously(for: time) { image, _, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: image)
                        }
                    }
                }
                
                if let cgImage {
                    let image = UIImage(cgImage: cgImage)
                    let cleanedImage = cropSafeImage(image)
                    cropPreviewImage = IdentifiableImage(image: cleanedImage)
                }
            } catch {
                print("Ошибка генерации кадра: \(error)")
            }
        }
    }
    
    private func cropSafeImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let cropWidth = width > 1 ? width - 1 : width
        let cropRect = CGRect(x: 0, y: 0, width: cropWidth, height: height)
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    @MainActor
    private func applyCropToCurrentVideo() async {
        guard let playerItem = playerItem, let asset = videoAsset else { return }

        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else { return }

            let naturalSize = try await videoTrack.load(.naturalSize)
            let duration = try await asset.load(.duration)

            // Переводим cropOffset из экранных координат в координаты видео
            let screenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            let scaleRatio = naturalSize.width / screenSize.width

            let transformedOffset = CGSize(
                width: cropOffset.width * scaleRatio,
                height: cropOffset.height * scaleRatio
            )

            let composition = AVMutableVideoComposition()
            composition.renderSize = naturalSize
            composition.frameDuration = CMTime(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

            // 🔍 Едва заметное увеличение масштаба для устранения черных полос
            let epsilon: CGFloat = 0.002
            let adjustedScale = cropScale + epsilon

            // 🧠 Сначала сдвиг, потом масштаб — соответствует редактору
            let transform = CGAffineTransform.identity
                .translatedBy(x: transformedOffset.width, y: transformedOffset.height)
                .scaledBy(x: adjustedScale, y: adjustedScale)

            layerInstruction.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]

            playerItem.videoComposition = composition

        } catch {
            print("❌ Ошибка при применении кропа: \(error)")
        }
    }
}
