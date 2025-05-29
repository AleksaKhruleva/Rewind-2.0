// swiftlint:disable line_length
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
                image: "https://avatars.mds.yandex.net/i?id=69f88251729e08e874dd925efa4f6d52_l-5228667-images-thumbs&n=13",
                username: "some_cool_name",
                createdAt: "some_cool_date"
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
// swiftlint:enable line_length
