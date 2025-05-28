public struct GroupMemberResponse: Decodable {
    public let id: Int
    public let name: String
    public let imageURL: String
    public let isOwner: Bool
    public let memoriesAddedCount: Int
    public let memoriesViewedCount: Int
    public let joinedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "username"
        case imageURL = "user_image"
        case isOwner = "is_admin"
        case memoriesAddedCount = "memories_added_count"
        case memoriesViewedCount = "memories_viewed_count"
        case joinedAt = "joined_at"
    }
}
