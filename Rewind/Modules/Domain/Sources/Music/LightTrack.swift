import Foundation

public struct LightTrack: Codable, Hashable {
    public let id: String
    public let title: String
    public let artistName: String
    public let startTime: Double
    public let duration: Double
    public let media: Media?
    public var streamURL: URL?
    
    public init(
        id: String,
        title: String,
        artistName: String,
        startTime: Double,
        duration: Double,
        media: Media? = nil,
        streamURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.startTime = startTime
        self.duration = duration
        self.media = media
        self.streamURL = streamURL
    }
}
