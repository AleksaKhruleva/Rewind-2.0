import UIKit

public enum MediaType {
    case image
    case imageWithMusic
    case video
}

public struct MediaItem: Identifiable {
    public let id: UUID
    public let type: MediaType
    public let image: UIImage
    public let track: Track?
    public let videoURL: URL?
    
    public init(
        id: UUID = UUID(),
        type: MediaType,
        image: UIImage,
        track: Track? = nil,
        videoURL: URL? = nil
    ) {
        self.id = id
        self.type = type
        self.image = image
        self.track = track
        self.videoURL = videoURL
    }
}
