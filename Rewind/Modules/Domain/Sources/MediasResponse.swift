import SwiftUI
import PhotosUI

public struct MediaResponse: Codable {
    public let id: Int
    public let groupId: Int
    public let userId: Int
    public let username: String
    public let userImage: String?
    public let mediaType: String
    public let mediaURL: URL?
    public let latitude: Double?
    public let longitude: Double?
    public let musicId: String?
    public let offset: Double?
    public let duration: Double?
    public let createdAt: String
    public let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId
        case userId
        case username
        case userImage
        case mediaType
        case mediaURL = "mediaUrl"
        case latitude
        case longitude
        case musicId
        case offset
        case duration
        case createdAt
        case updatedAt
    }
    
    public func toMediaItem() -> MediaItem {
        MediaItem(
            id: self.id,
            userId: self.userId,
            groupId: self.groupId,
            username: self.username,
            userImage: URL(string: self.userImage ?? ""),
            mediaType: self.mediaType.toMediaType(),
            mediaURL: self.mediaURL,
            latitude: self.latitude,
            longitude: self.longitude,
            duration: self.duration,
            offset: self.offset,
            createdAt: self.createdAt.toRewindDate(),
        )
    }
}

public struct MediasResponseItem: Codable {
    public let isFavourite: Bool
    public let memory: MediaResponse
    public let tags: [String]?
    
    public func toGalleryItem() -> GalleryItem {
        .init(
            isFavourite: isFavourite,
            tags: tags ?? [],
            memory: memory.toMediaItem()
        )
    }
}

public struct MediasResponse: Codable {
    public let memories: [MediasResponseItem]?
}

extension String {
    fileprivate func toRewindDate() -> Self {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: self) else {
            return "N/D"
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        outputFormatter.timeZone = .current

        return outputFormatter.string(from: date)
    }
}
