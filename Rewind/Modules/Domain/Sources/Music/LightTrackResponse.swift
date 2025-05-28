public struct LightTrackResponse: Decodable {
    public let id: Int
    public let title: String
    public let artist: ArtistResponse
    public let media: Media?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist = "user"
        case media
    }
    
    public func toLightTrack(with info: TrackInformation) -> LightTrack {
        LightTrack(
            id: String(id),
            title: title,
            artistName: artist.name,
            startTime: info.startTime,
            duration: info.duration,
            media: media,
            streamURL: nil
        )
    }
}

public struct ArtistResponse: Decodable {
    public let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "username"
    }
}
