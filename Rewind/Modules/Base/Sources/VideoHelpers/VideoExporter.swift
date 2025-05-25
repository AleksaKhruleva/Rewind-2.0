import AVFoundation
import Domain

public final class VideoExporter {
    private let transformer: PhotosPickerItemTransformer

    public init() {
        transformer = PhotosPickerItemTransformer()
    }

    public func export(from media: LoadedMedia, options: VideoEditingSettings) async throws -> LoadedMedia {
        guard case let .video(url, _) = media.content else {
            throw NSError(
                domain: "VideoExportService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Media is not video"]
            )
        }

        let asset = AVURLAsset(url: url)
        return try await exportFromAsset(asset, options: options)
    }

    // swiftlint:disable function_body_length
    private func exportFromAsset(
        _ asset: AVURLAsset,
        options: VideoEditingSettings
    ) async throws -> LoadedMedia {
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: options.startTime, end: options.endTime)

        // VIDEO
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw NSError(
                domain: "VideoExportService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No video track found"]
            )
        }

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(
                domain: "VideoExportService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create video track"]
            )
        }

        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        // AUDIO
        if !options.isMuted {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            if let audioTrack = audioTracks.first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
               ) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
        }

        // VIDEO COMPOSITION (to apply preferredTransform)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let renderSize = CGSize(
            width: abs(naturalSize.applying(preferredTransform).width),
            height: abs(naturalSize.applying(preferredTransform).height)
        )

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)
        instruction.layerInstructions = [layerInstruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = renderSize

        // EXPORT
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(
                domain: "VideoExportService",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]
            )
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = options.composition
        exportSession.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)

        try await exportSession.export(to: outputURL, as: .mp4)

        // FIRST FRAME
        let firstFrameImage = try await transformer.makeImageFromVideo(url: outputURL, at: options.startTime.seconds)

        return LoadedMedia(content: .video(url: outputURL, firstFrame: firstFrameImage))
    }
    // swiftlint:enable function_body_length
}
