import AVFoundation
import Photos
import SwiftUI
import Domain
import UIComponents

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
        case updateTime
        case changeTrim
    }
    
    // MARK: - Constants
    public static let frameCount = 11
    private static let maxVideoDuration: CMTime = CMTime(seconds: 15, preferredTimescale: 600)
    
    // MARK: - Init
    init() {}
    
    // MARK: - Published Properties
    var toastMessage: String? = nil
    
    var tags = [String]()
    
    var videoPickerPresented = false
    
    var isPlaying = false
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
    
    // MARK: - Private State
    private var playerItem: AVPlayerItem?
    
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
                await applyCrop(scale: scale, offset: offset)
            }
        case .cropVideo:
            isPlaying = false
            generateCurrentFrameImage()
        case .completeSeek:
            shouldSeekToStartTime = false
            syncCurrentTime()
        case .updateTime:
            updateCurrentTime()
        case .changeTrim:
            isPlaying = false
            shouldSeekToStartTime = true
        }
    }
    
    // MARK: - Private Methods
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
        player = nil
        isPlaying = false
    }
    
    private func handleVideoEnd() {
        guard let player = player else { return }
        player.pause()
        player.seek(to: startTime)
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
            self.startTime = .zero
            self.endTime = clampedDuration
            self.duration = CMTimeGetSeconds(videoDuration)
            
            let item = AVPlayerItem(asset: asset)
            self.playerItem = item
            
            let newPlayer = AVPlayer(playerItem: item)
            await newPlayer.seek(to: .zero)
            self.player = newPlayer
            self.isPlaying = false
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.player?.seek(to: self.startTime)
                    self.isPlaying = false
                }
            }
        } catch {
            print("Failed to load video: \(error)")
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
    
    private func applyCrop(scale cropScale: CGFloat, offset cropOffset: CGSize) async {
        guard let playerItem = playerItem, let asset = videoAsset else { return }
        
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else { return }
            
            let naturalSize = try await videoTrack.load(.naturalSize)
            let duration = try await asset.load(.duration)
            let preferredTransform = try await videoTrack.load(.preferredTransform)
            
            let isPortrait = abs(preferredTransform.b) == 1 && abs(preferredTransform.c) == 1
            let renderSize = isPortrait
            ? CGSize(width: naturalSize.height, height: naturalSize.width)
            : naturalSize
            
            let cropFrameSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            
            let fittingScale = max(
                cropFrameSize.width / renderSize.width,
                cropFrameSize.height / renderSize.height
            )
            
            let renderedVideoSize = CGSize(
                width: renderSize.width * fittingScale,
                height: renderSize.height * fittingScale
            )
            
            let scaleRatio = renderSize.width / renderedVideoSize.width
            
            let minimalOffset: CGFloat = 0.5
            let adjustedCropOffset = CGSize(
                width: abs(cropOffset.width) < minimalOffset ? 0 : cropOffset.width,
                height: abs(cropOffset.height) < minimalOffset ? 0 : cropOffset.height
            )
            
            let transformedOffset = CGSize(
                width: round(adjustedCropOffset.width * scaleRatio),
                height: round(adjustedCropOffset.height * scaleRatio)
            )
            
            let epsilon: CGFloat = 0.002
            let adjustedScale = cropScale + epsilon
            
            let anchor = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
            
            let scaleTransform = CGAffineTransform.identity
                .translatedBy(x: anchor.x, y: anchor.y)
                .scaledBy(x: adjustedScale, y: adjustedScale)
                .translatedBy(x: -anchor.x, y: -anchor.y)
            
            let offsetTransform = CGAffineTransform(translationX: transformedOffset.width, y: transformedOffset.height)
            
            let cropTransform = scaleTransform.concatenating(offsetTransform)
            
            let finalTransform = preferredTransform.concatenating(cropTransform)
            
            let composition = AVMutableVideoComposition()
            composition.renderSize = renderSize
            composition.frameDuration = CMTime(value: 1, timescale: 30)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstruction.setTransform(finalTransform, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]
            
            playerItem.videoComposition = composition
        } catch {
            //            toastMessage = UIComponentsStrings.Video.CropVideo.failure
            print("Ошибка при применении кропа: \(error)")
        }
    }
}
