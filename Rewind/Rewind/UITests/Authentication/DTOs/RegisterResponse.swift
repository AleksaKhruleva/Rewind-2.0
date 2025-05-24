import Vapor

struct RegistrationResponse: Content {
    let registrationID: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case success
    }
}
