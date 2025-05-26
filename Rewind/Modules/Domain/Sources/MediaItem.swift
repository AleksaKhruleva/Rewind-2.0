import UIKit

public enum MediaType: Codable {
    case image
    case video
    case quote
}

public struct MediaItem: Identifiable, Codable {
    public let id: UUID
    public let userId: Int
    public let groupId: Int
    public let mediaType: MediaType
    public let mediaURL: URL?
    public let latitude: Double?
    public let longitude: Double?
    public let duration: Double?
    public let offset: Double?
    public let createdAt: String
    
    public let track: Track?
//    public let image: UIImage
    
    public init(
        id: UUID = UUID(),
        userId: Int,
        groupId: Int,
        mediaType: MediaType,
        mediaURL: URL? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        duration: Double? = nil,
        offset: Double? = nil,
        createdAt: String,
        track: Track? = nil,
//        image: UIImage
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.latitude = latitude
        self.longitude = longitude
        self.duration = duration
        self.offset = offset
        self.createdAt = createdAt
        self.track = track
//        self.image = image
    }
}
