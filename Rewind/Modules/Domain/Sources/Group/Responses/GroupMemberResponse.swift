public struct GroupMemberResponse: Decodable {
    public let id: Int
    public let name: String
    public let isOwner: Bool
    public let memoriesAddedCount: Int
    public let memoriesViewedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "username"
        case isOwner = "is_admin"
        case memoriesAddedCount = "memories_added_count"
        case memoriesViewedCount = "memories_viewed_count"
    }
}
