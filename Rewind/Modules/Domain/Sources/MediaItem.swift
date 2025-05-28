import UIKit

public enum MediaType: Codable {
    case image
    case video
    case quote
}

public struct MediaItem: Identifiable, Codable, Hashable {
    public let id: Int
    public let userId: Int
    public let groupId: Int
    public let username: String
    public let userImage: URL?
    public let mediaType: MediaType
    public let mediaURL: URL?
    public let latitude: Double?
    public let longitude: Double?
    public let createdAt: String
    
    public let trackInfo: TrackInformation?
    public var lightTrack: LightTrack?
    
    public init(
        id: Int = -1,
        userId: Int,
        groupId: Int,
        username: String,
        userImage: URL?,
        mediaType: MediaType,
        mediaURL: URL? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        musicId: String? = nil,
        duration: Double? = nil,
        offset: Double? = nil,
        createdAt: String
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.username = username
        self.userImage = userImage
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        
        if let musicId, !musicId.isEmpty, let offset, let duration {
            self.trackInfo = TrackInformation(id: musicId, startTime: offset, duration: duration)
        } else {
            self.trackInfo = nil
        }
    }
}

extension MediaItem {
    public static func stubs(track: Track? = nil) -> [MediaItem] {
        [
            MediaItem(
                userId: 1,
                groupId: 1,
                username: "some user",
                userImage: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                mediaType: .image,
                mediaURL: URL(string: "https://pushinka.top/uploads/posts/2023-08/1692812086_pushinka-top-p-smekh-kartinki-smeshnie-vkontakte-13.jpg"),
                createdAt: "23.11.2024"
            ),
            MediaItem(
                userId: 2,
                groupId: 2,
                username: "some user cool",
                userImage: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                mediaType: .image,
                mediaURL: URL(string: "https://i.pinimg.com/originals/54/93/42/54934276d19ad7a7dc396dc8069bc485.jpg"),
                createdAt: "01.01.2025"
            ),
            MediaItem(
                userId: 3,
                groupId: 3,
                username: "some user krut",
                userImage: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                mediaType: .image,
                mediaURL: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                createdAt: "01.01.2025"
            ),
            MediaItem(
                userId: 4,
                groupId: 4,
                username: "картошечка",
                userImage: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                mediaType: .image,
                mediaURL: URL(string: "https://i.pinimg.com/736x/80/09/ca/8009ca0a8bb73d596838a57d4c8fa491.jpg"),
                createdAt: "04.02.2022"
            ),
            MediaItem(
                userId: 5,
                groupId: 5,
                username: "картофанчик",
                userImage: URL(string: "https://i2-prod.dailyrecord.co.uk/incoming/article1906467.ece/ALTERNATES/s1227b/laughing-animals.jpg"),
                mediaType: .video,
                mediaURL: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4"),
                createdAt: "23.11.2024"
            )
        ]
    }
}

extension String {
    public func toMediaType() -> MediaType {
        switch self {
        case "image": .image
        case "video": .video
        case "quote": .quote
        default: .image
        }
    }
}
