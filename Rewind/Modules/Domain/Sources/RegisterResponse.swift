public struct RegisterResponse: Codable {
    public let registrationID: String
    public let success: Bool

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case success
    }
}
