import SwiftUI

public struct Group: Hashable, Identifiable {
    public let id: Int
    public var name: String
    public let ownerID: Int
    public var imageURL: String
    public let createdAt: Date?
    public var members: [Member]?
    public let gallery: [UIImage]?
    
    public var daysSinceCreation: Int {
        guard let createdAt else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    public init(
        id: Int,
        name: String,
        ownerID: Int = -1,
        imageURL: String,
        createdAt: Date? = nil,
        members: [Member]? = nil,
        gallery: [UIImage]? = nil
    ) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.imageURL = imageURL
        self.members = members
        self.createdAt = createdAt
        self.gallery = gallery
    }
}
