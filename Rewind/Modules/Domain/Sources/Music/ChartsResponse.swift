
public struct ChartsResponse: Decodable {
    public let collection: [ChartItem]
    public let next_href: String?
    
    public init(collection: [ChartItem], next_href: String?) {
        self.collection = collection
        self.next_href = next_href
    }
}
