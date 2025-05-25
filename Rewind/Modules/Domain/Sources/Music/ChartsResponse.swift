public struct ChartsResponse: Decodable {
    public let collection: [ChartItem]
    public let next_href: String?
}
