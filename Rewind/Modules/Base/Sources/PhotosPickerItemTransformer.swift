import SwiftUI
import PhotosUI
import Domain

public final class PhotosPickerItemTransformer {
    struct TransformItemError: Error {}
    
    public init() {}
    
    public func transform(source: PhotosPickerItem) async throws -> LoadedMedia {
        if let movie = try await source.loadTransferable(type: Movie.self) {
            let firstFrame = try await makeImageFromVideo(url: movie.url, at: 0)
            
            return LoadedMedia(content: .video(url: movie.url, firstFrame: firstFrame), photosPickerItem: source)
        }
        
        guard let data = try await source.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            throw TransformItemError()
        }
        
        return LoadedMedia(content: .image(image), photosPickerItem: source)
    }
    
    public func makeImageFromVideo(url: URL, at time: TimeInterval, composition: AVVideoComposition? = nil) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = composition == nil
        assetImageGenerator.apertureMode = .encodedPixels
        assetImageGenerator.videoComposition = composition
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let thumbnailImage = try await assetImageGenerator.image(at: cmTime).image
        return UIImage(cgImage: thumbnailImage)
    }
}

private struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let videoName = received.file.pathComponents.last ?? "movie.mp4"
            let copy = URL.cachesDirectory.appending(path: videoName)
            
            if FileManager.default.fileExists(atPath: copy.path) {
                return self.init(url: copy)
            }
            
            try FileManager.default.copyItem(at: received.file, to: copy)
            return self.init(url: copy)
        }
    }
}
