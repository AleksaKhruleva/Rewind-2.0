import Foundation

public struct MediaTag: Identifiable, Hashable, Codable {
    public var id: UUID?
    public let tag: String
    
    public init(tag: String) {
        self.id = UUID()
        self.tag = tag
    }
}

public struct TagsResponse: Codable {
    public let tags: [MediaTag]
}
