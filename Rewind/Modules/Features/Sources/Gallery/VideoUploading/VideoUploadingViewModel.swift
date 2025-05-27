import AVFoundation
import Photos
import SwiftUI
import Domain
import UIComponents
import Base

@MainActor @Observable
final class VideoUploadingViewModel {
    // MARK: - Types
    enum Intent {
        case selectVideoInGallery(PHAsset)
        case initializePlayer(AVURLAsset)
        case viewGallery
        case cropVideo
        case applyCrop(scale: CGFloat, offset: CGSize)
        case completeSeek
        case changeTrim
        case saveSettings
    }

    // MARK: - Constants
    public static let frameCount = 11
    private static let maxVideoDuration: CMTime = CMTime(seconds: 15, preferredTimescale: 600)

    // MARK: - Published Properties
    var isSettingsSaved = false

    var loadedMedia: LoadedMedia?
    var toastMessage: String? // TODO: implement later

    var tags: [MediaTag] {
        get { loadedMedia?.tags ?? [] }
        set { loadedMedia?.tags = newValue }
    }

    var videoPickerPresented = false

    var isPlaying = false
    var isMuted = false
    var player: AVPlayer?
    var videoAsset: AVURLAsset?

    var shouldSeekToStartTime = false
    var startTime: CMTime = .zero
    var endTime: CMTime = .zero
    var duration: TimeInterval = 1
    var currentTime: TimeInterval = 0
    var timelineID = UUID()

    var trimStartAsSeconds: TimeInterval {
        get { startTime.seconds }
        set { startTime = CMTime(seconds: newValue, preferredTimescale: 600) }
    }

    var trimEndAsSeconds: TimeInterval {
        get { endTime.seconds }
        set { endTime = CMTime(seconds: newValue, preferredTimescale: 600) }
    }

    var cropPreviewImage: IdentifiableImage?

    private let photoTransformer: PhotosPickerItemTransformer
    private let videoTransformer: VideoTransformer
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    // MARK: - Init

    init(loadedMedia: LoadedMedia?) {
        photoTransformer = PhotosPickerItemTransformer()
        videoTransformer = VideoTransformer()
        self.loadedMedia = loadedMedia
        if case let .video(url, _) = loadedMedia?.content {
            Task {
                await initializePlayer(for: AVURLAsset(url: url))
            }
        }
    }

    // MARK: - Intents
    func dispatch(_ intent: Intent) {
        switch intent {
        case let .selectVideoInGallery(asset):
            resetPlayer()
            loadVideoAsset(from: asset)
        case let .initializePlayer(asset):
            resetPlayer()
            Task {
                await initializePlayer(for: asset)
            }
        case .viewGallery:
            isPlaying = false
            videoPickerPresented = true
        case let .applyCrop(scale, offset):
            Task {
                guard let videoAsset else { return }
                let composition = try await videoTransformer.makeVideoComposition(
                    from: videoAsset,
                    cropScale: scale,
                    cropOffset: offset
                )
                playerItem?.videoComposition = composition
            }
        case .cropVideo:
            isPlaying = false
            Task {
                guard let url = videoAsset?.url else { return }
                do {
                    let currentFrame = try await photoTransformer.makeImageFromVideo(
                        url: url,
                        at: currentTime
                    )
                    cropPreviewImage = IdentifiableImage(image: cropSafeImage(currentFrame))
                } catch {
                    print("Aboba \(error)")
                }
            }
        case .completeSeek:
            shouldSeekToStartTime = false
            currentTime = startTime.seconds
        case .changeTrim:
            isPlaying = false
            shouldSeekToStartTime = true
            Task {
                guard let player else { return }
                await player.seek(
                    to: startTime,
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
                currentTime = startTime.seconds
            }
        case .saveSettings:
            loadedMedia?.videoEditingSettings = VideoEditingSettings(
                startTime: startTime,
                endTime: endTime,
                isMuted: isMuted,
                composition: playerItem?.videoComposition
            )
            Task {
                guard let url = videoAsset?.url else { return }
                do {
                    let firstFrame = try await photoTransformer.makeImageFromVideo(
                        url: url,
                        at: startTime.seconds,
                        composition: playerItem?.videoComposition
                    )
                    loadedMedia?.content = .video(url: url, firstFrame: firstFrame)
                    isSettingsSaved = true
                } catch {
                    print("Aboba \(error)")
                }
            }
        }
    }

    // MARK: - Private Methods

    private func resetPlayer() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        playerItem = nil
        videoAsset = nil
        player = nil
        isPlaying = false
        cropPreviewImage = nil
        startTime = .zero
        endTime = .zero
        timelineID = UUID()
    }

    private func handleVideoEnd() {
        guard let player = player else { return }
        player.pause()
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
        isPlaying = false
    }

    private func loadVideoAsset(from asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else { return }

            Task { @MainActor in
                await self.initializePlayer(for: urlAsset)
            }
        }
    }

    private func initializePlayer(for asset: AVURLAsset) async {
        do {
            let videoDuration = try await asset.load(.duration)
            let clampedDuration = CMTimeMinimum(videoDuration, Self.maxVideoDuration)

            self.videoAsset = asset
            self.timelineID = UUID()
            self.currentTime = 0

            self.startTime = loadedMedia?.videoEditingSettings?.startTime ?? .zero
            self.endTime = loadedMedia?.videoEditingSettings?.endTime ?? clampedDuration
            self.isMuted = loadedMedia?.videoEditingSettings?.isMuted ?? false

            self.duration = CMTimeGetSeconds(videoDuration)

            let item = AVPlayerItem(asset: asset)
            item.videoComposition = loadedMedia?.videoEditingSettings?.composition
            self.playerItem = item

            let newPlayer = AVPlayer(playerItem: item)
            self.player = newPlayer
            await newPlayer.seek(to: self.startTime, toleranceBefore: .zero, toleranceAfter: .zero)
            self.isPlaying = false

            let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
            self.timeObserver = newPlayer.addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main
            ) { [weak self] currentTime in
                guard let self else { return }
                Task { @MainActor in
                    self.currentTime = currentTime.seconds
                    if currentTime >= self.endTime - interval {
                        self.handleVideoEnd()
                    }
                }
            }
        } catch {
            print("Failed to load video: \(error)")
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
}
