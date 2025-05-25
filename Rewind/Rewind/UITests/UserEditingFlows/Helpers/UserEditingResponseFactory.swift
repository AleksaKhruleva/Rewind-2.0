import Vapor

struct UserEditingResponseFactory {
    let host: String

    static func make() -> UserEditingResponseFactory {
        UserEditingResponseFactory(host: "localhost")
    }

    func makeUserResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(
            UserResponse(
                email: "example@ex.com",
                id: 0,
                image: "some_image_URL",
                username: "some_cool_name"
            )
        )
        return response
    }

    func makeSuccessResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(SuccessResponse(success: true))
        return response
    }
}
