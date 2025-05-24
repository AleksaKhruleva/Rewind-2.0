import Foundation

public struct Track: Decodable, Identifiable {
    public let id: Int
    public let title: String
    public let artist: String
    public let artworkURL: URL?
    public let duration: TimeInterval
    public var durationString: String
    public let media: Media?
    public var streamURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, artwork_url, duration, user, media
    }

    enum UserKeys: String, CodingKey {
        case username
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.artworkURL = try container.decodeIfPresent(URL.self, forKey: .artwork_url)
        self.duration = try container.decode(Double.self, forKey: .duration) / 1000
        self.media = try container.decodeIfPresent(Media.self, forKey: .media)

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        self.durationString = String(format: "%d:%02d", minutes, seconds)

        let user = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        self.artist = try user.decode(String.self, forKey: .username)
    }
}
