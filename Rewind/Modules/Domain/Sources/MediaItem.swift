import UIKit

public enum MediaType {
    case image
    case imageWithMusic
    case video
}

public struct MediaItem {
    public let type: MediaType
    public let image: UIImage?
    public let track: Track?
    public let videoURL: URL?
    
    public init(
        type: MediaType,
        image: UIImage? = nil,
        track: Track? = nil,
        videoURL: URL? = nil
    ) {
        self.type = type
        self.image = image
        self.track = track
        self.videoURL = videoURL
    }
}
