public struct Format: Codable {
    public let protocolType: String
    
    enum CodingKeys: String, CodingKey {
        case protocolType = "protocol"
    }
}
