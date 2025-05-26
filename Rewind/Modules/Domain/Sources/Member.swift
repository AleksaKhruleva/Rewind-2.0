import Foundation
import SwiftUI

public struct Member: Identifiable, Hashable {
    public let id: String
    public let name: String
    public private(set) var imageData: Data?
    public let isOwner: Bool
    public let isUser: Bool
    
    public var image: UIImage {
        get {
            guard let imageData = imageData, let image = UIImage(data: imageData) else { return DomainAsset.userPlacholder.image }
            return image
        }
        set {
            imageData = newValue.pngData()
        }
    }
    
    public init(
        id: String,
        name: String,
        imageData: Data? = nil,
        isOwner: Bool = false,
        isUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.isOwner = isOwner
        self.isUser = isUser
    }
}
