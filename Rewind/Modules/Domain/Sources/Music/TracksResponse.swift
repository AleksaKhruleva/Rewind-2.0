
public struct TracksResponse: Decodable {
    public let collection: [Track]
    public let next_href: String?
    
    public init(collection: [Track], next_href: String?) {
        self.collection = collection
        self.next_href = next_href
    }
}
