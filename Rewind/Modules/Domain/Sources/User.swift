public struct User: Codable {
    public var name: String
    public var email: String
    
    public init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}
