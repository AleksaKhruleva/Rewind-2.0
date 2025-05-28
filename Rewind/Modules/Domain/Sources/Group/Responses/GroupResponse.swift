import Foundation

public struct GroupResponse: Codable {
    public let groupID: Int
    public let ownerID: Int
    public let name: String
    public let imageURL: String
    public let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case groupID = "id"
        case ownerID = "admin_user_id"
        case name
        case imageURL = "image"
        case createdAt = "created_at"
    }
}
