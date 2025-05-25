public struct UserAccessTokenResponse: Codable {
    public let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
