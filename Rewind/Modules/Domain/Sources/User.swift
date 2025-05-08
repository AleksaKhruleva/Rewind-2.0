import SwiftUI

public struct User: Codable {
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
    
    public init(name: String, email: String, image: UIImage? = nil) {
        self.name = name
        self.email = email
        self.imageData = image?.pngData()
    }
}
