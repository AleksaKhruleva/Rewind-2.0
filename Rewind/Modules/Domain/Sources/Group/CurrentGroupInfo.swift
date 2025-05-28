import Foundation

public struct CurrentGroupInfo: Codable {
    public let id: Int
    public var name: String
    public let imageURL: String
    
    public init(id: Int, name: String, imageURL: String) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }
}
