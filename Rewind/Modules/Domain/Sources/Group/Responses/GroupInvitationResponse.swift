public struct GroupInvitationCodeResponse: Decodable {
    public let invitationCode: String
    public let error: String?
    
    enum CodingKeys: String, CodingKey {
        case invitationCode = "invitation_code"
        case error
    }
}
