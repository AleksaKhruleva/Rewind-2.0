import Foundation

public struct CurrentGroupInfo: Codable {
    public let id: Int
    public let imageData: Data?
    
    public init(id: Int, imageData: Data?) {
        self.id = id
        self.imageData = imageData
    }
}
