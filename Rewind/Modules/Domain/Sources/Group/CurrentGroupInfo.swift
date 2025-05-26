import Foundation

public struct CurrentGroupInfo: Codable {
    public let id: Int
    public var name: String
    public let imageData: Data?
    
    public init(id: Int, name: String, imageData: Data?) {
        self.id = id
        self.name = name
        self.imageData = imageData
    }
}
