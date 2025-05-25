import Vapor

struct AuthenticationResponseFactory {
    let host: String

    static func make() -> AuthenticationResponseFactory {
        AuthenticationResponseFactory(host: "localhost")
    }

    func makeRegisterResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(RegistrationResponse(registrationID: "some_registration_id", success: true))
        return response
    }

    func makeVerifyResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(["success": true])
        return response
    }

    func makeFinishResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(TokensResponse(accessToken: "some_atoken", refreshToken: "some_rtoken"))
        return response
    }

    func makeLoginResponse() -> Response {
        let response = Response(status: .ok)
        try? response.content.encode(TokensResponse(accessToken: "some_atoken", refreshToken: "some_rtoken"))
        return response
    }
}
