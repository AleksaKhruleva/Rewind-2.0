import Foundation

public struct Transcoding: Decodable, Hashable {
    public let url: URL
    public let format: Format
}
