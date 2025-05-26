public struct TagResponse: Codable {
    public let tag: String
}

public struct TagsResponse: Codable {
    public let tags: [TagResponse]
}
