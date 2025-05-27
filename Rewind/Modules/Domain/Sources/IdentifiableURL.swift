import Foundation

public struct IdentifiableURL: Identifiable {
    public let id: String
    public let url: URL
    
    public init(_ url: URL) {
        self.url = url
        self.id = url.absoluteString
    }
}
