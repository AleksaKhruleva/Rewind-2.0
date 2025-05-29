import SwiftUI

public struct User: Codable, Hashable {
    public var name: String
    public var email: String
    public let invitedMembers: Int
    public let memoriesAdded: Int
    public let memoriesViewed: Int
    public var imageURL: String
    public let createdAt: String

    public var isEmpty: Bool {
        name.isEmpty && email.isEmpty
    }

    public init(
        name: String,
        email: String,
        imageURL: String,
        invitedMembers: Int,
        memoriesAdded: Int,
        memoriesViewed: Int,
        createdAt: String
    ) {
        self.name = name
        self.email = email
        self.imageURL = imageURL
        self.invitedMembers = invitedMembers
        self.memoriesAdded = memoriesAdded
        self.memoriesViewed = memoriesViewed
        self.createdAt = createdAt
    }
}

public struct UserResponse: Codable {
    public let email: String
    public let id: Int
    public let image: String
    public let invitedMembers: Int
    public let memoriesAdded: Int
    public let memoriesViewed: Int
    public let username: String
    public let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case id
        case image
        case invitedMembers = "invited_members_count"
        case memoriesAdded = "memories_added_count"
        case memoriesViewed = "memories_viewed_count"
        case username
        case createdAt = "created_at"
    }

    public func toUser() -> User {
        return User(
            name: username,
            email: email,
            imageURL: image,
            invitedMembers: invitedMembers,
            memoriesAdded: memoriesAdded,
            memoriesViewed: memoriesViewed,
            createdAt: createdAt
        )
    }
}
