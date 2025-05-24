import SwiftUI

public struct User: Codable, Hashable {
    public var name: String
    public var email: String
    public var imageData: Data?
    
    public var image: UIImage {
        get {
            guard let imageData = imageData, let image = UIImage(data: imageData) else { return DomainAsset.userPlacholder.image }
            return image
        }
        set {
            imageData = newValue.pngData()
        }
    }
    
    public var isEmpty: Bool {
        name.isEmpty && email.isEmpty
    }
    
    public init(name: String, email: String, image: UIImage? = nil) {
        self.name = name
        self.email = email
        self.imageData = image?.pngData()
    }
}

public struct UserResponse: Codable {
    public let email: String
    public let id: Int
    public let image: String
    public let username: String
    
    public func toUser() -> User {
        return User(name: username, email: email, image: nil)
    }
}
