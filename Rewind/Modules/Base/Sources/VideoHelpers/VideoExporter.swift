import AVFoundation
import Domain

public final class VideoExporter {
    private let transformer = PhotosPickerItemTransformer()
    private let videoTransformer = VideoTransformer()

    public init() {}

    public func export(from media: LoadedMedia, options: VideoEditingSettings) async throws -> LoadedMedia {
        guard case let .video(url, _) = media.content else {
            throw NSError(
                domain: "VideoExportService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Media is not video"]
            )
        }

        let originalAsset = AVURLAsset(url: url)
        let timeRange = CMTimeRange(start: options.startTime, end: options.endTime)

        var exportAsset: AVAsset = originalAsset

        if !options.isMuted {
            let composition = AVMutableComposition()

            let videoTracks = try await originalAsset.loadTracks(withMediaType: .video)
            guard let videoTrack = videoTracks.first,
                  let compositionVideoTrack = composition.addMutableTrack(
                      withMediaType: .video,
                      preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                throw NSError(
                    domain: "VideoExportService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to prepare video track"]
                )
            }
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

            let audioTracks = try await originalAsset.loadTracks(withMediaType: .audio)
            if let audioTrack = audioTracks.first,
               let compositionAudioTrack = composition.addMutableTrack(
                   withMediaType: .audio,
                   preferredTrackID: kCMPersistentTrackID_Invalid
               ) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }

            exportAsset = composition
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(
            asset: exportAsset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(
                domain: "VideoExportService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]
            )
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.timeRange = timeRange

        let originalVideoTrack = try await originalAsset.loadTracks(withMediaType: .video).first!
        let preferredTransform = try await originalVideoTrack.load(.preferredTransform)

        exportSession.videoComposition = try await videoTransformer.makeVideoComposition(
            from: exportAsset,
            cropScale: options.cropScale,
            cropOffset: options.cropOffset,
            preferredTransform: preferredTransform
        )

        try await exportSession.export(to: outputURL, as: .mp4)

        let firstFrameImage = try await transformer.makeImageFromVideo(url: outputURL, at: options.startTime.seconds)

        return LoadedMedia(content: .video(url: outputURL, firstFrame: firstFrameImage))
    }
}
