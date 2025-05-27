import SwiftUI

public struct Group: Hashable, Identifiable {
    public let id: Int
    public var name: String
    public let ownerID: Int?
    public private(set) var imageData: Data?
    public var members: [Member]?
    public let createdAt: Date?
    public let gallery: [UIImage]?
    
    public var image: UIImage {
        get {
            guard let imageData = imageData, let image = UIImage(data: imageData) else {
                return DomainAsset.groupPlaceholder.image
            }
            return image
        }
        set {
            imageData = newValue.pngData()
        }
    }
    
    public var daysSinceCreation: Int? {
        guard let createdAt else { return nil }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: Date())
        
        return calendar.dateComponents([.day], from: start, to: end).day
    }
    
    public init(
        id: Int,
        name: String,
        ownerID: Int? = nil,
        imageData: Data? = nil,
        members: [Member]? = nil,
        createdAt: Date? = nil,
        gallery: [UIImage]? = nil
    ) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.imageData = imageData
        self.members = members
        self.createdAt = createdAt
        self.gallery = gallery
    }
}
