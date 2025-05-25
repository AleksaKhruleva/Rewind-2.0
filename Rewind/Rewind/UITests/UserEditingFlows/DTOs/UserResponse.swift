import Vapor

struct UserResponse: Content {
    let email: String
    let id: Int
    let image: String
    let username: String
}
