import Foundation

public struct Transcoding: Codable, Hashable {
    public let url: URL
    public let format: Format
    
    public static func == (lhs: Transcoding, rhs: Transcoding) -> Bool {
        lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
