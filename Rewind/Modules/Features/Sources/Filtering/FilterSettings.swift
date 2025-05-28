public struct FilterSettings: Equatable {
    var photos: Bool
    var videos: Bool
    var quotes: Bool

    var mediaTypes: String {
        var mediaTypes = [String]()
        if photos { mediaTypes.append("image")}
        if videos { mediaTypes.append("video")}
        if quotes { mediaTypes.append("quote")}
        return mediaTypes.joined(separator: ",")
    }

    var favourites: Bool?

    var startDate: String?
    var endDate: String?

    var tags: [String]?

    var areDefault: Bool {
        self == FilterSettings()
    }

    init(
        photos: Bool = true,
        videos: Bool = true,
        quotes: Bool = true,
        favourites: Bool? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        tags: [String]? = nil
    ) {
        self.photos = photos
        self.videos = videos
        self.quotes = quotes
        self.favourites = favourites
        self.startDate = startDate
        self.endDate = endDate
        self.tags = tags
    }
}
