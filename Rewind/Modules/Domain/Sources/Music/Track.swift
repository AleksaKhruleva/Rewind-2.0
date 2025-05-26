import Foundation

public struct Artist: Codable, Hashable {
    public let username: String
}

public struct Track: Identifiable, Codable, Hashable {
    public let id: Int
    public let title: String
    public let artist: Artist
    public let artworkURL: URL?
    public let duration: TimeInterval
    public var durationString: String
    public let media: Media?
    public var streamURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artworkURL = "artwork_url"
        case duration
        case media
        case artist = "user"
    }

    enum UserKeys: String, CodingKey {
        case username
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        self.duration = try container.decode(Double.self, forKey: .duration) / 1000
        self.media = try container.decodeIfPresent(Media.self, forKey: .media)

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        self.durationString = String(format: "%d:%02d", minutes, seconds)

        self.artist = try container.decode(Artist.self, forKey: .artist)
    }
}
