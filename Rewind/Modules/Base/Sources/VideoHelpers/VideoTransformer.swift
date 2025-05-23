import AVFoundation
import UIKit

public final class VideoTransformer {
    public init() {}
    
    public func makeVideoComposition(
        from asset: AVAsset,
        cropScale: CGFloat,
        cropOffset: CGSize
    ) async throws -> AVMutableVideoComposition {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw NSError(domain: "VideoTransformer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track"])
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let duration = try await asset.load(.duration)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        let isPortrait = abs(preferredTransform.b) == 1 && abs(preferredTransform.c) == 1
        let renderSize = isPortrait ? CGSize(width: naturalSize.height, height: naturalSize.width) : naturalSize
        
        let cropFrameSize = await CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        
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
        
        let anchor = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
        
        let scaleTransform = CGAffineTransform.identity
            .translatedBy(x: anchor.x, y: anchor.y)
            .scaledBy(x: cropScale, y: cropScale)
            .translatedBy(x: -anchor.x, y: -anchor.y)
        
        let offsetTransform = CGAffineTransform(translationX: transformedOffset.width, y: transformedOffset.height)
        
        let cropTransform = scaleTransform.concatenating(offsetTransform)
        let finalTransform = preferredTransform.concatenating(cropTransform)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(finalTransform, at: .zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.layerInstructions = [layerInstruction]
        
        let composition = AVMutableVideoComposition()
        composition.instructions = [instruction]
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        
        return composition
    }
}
