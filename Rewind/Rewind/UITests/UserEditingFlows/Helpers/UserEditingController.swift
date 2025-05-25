import Vapor

struct UserEditingController: RouteCollection {
    let responseFactory: UserEditingResponseFactory

    static func make(with factory: UserEditingResponseFactory) -> UserEditingController {
        UserEditingController(responseFactory: factory)
    }

    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(":id", use: user)
        users.patch("username", use: username)

        users.post("password", "reset", "start", use: passwordResetStart)
        users.post("password", "reset", "verify", use: passwordResetVerify)
        users.patch("password", "reset", "set", use: passwordResetSet)

        users.post("check-password", use: checkPassword)
        users.post("email", "start-change", use: emailStartChange)
        users.patch("email", "verify-change", use: emailVerifyChange)
    }

    func user(req: Request) throws -> Response {
        return responseFactory.makeUserResponse()
    }

    func username(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func passwordResetStart(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func passwordResetVerify(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func passwordResetSet(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func checkPassword(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func emailStartChange(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }

    func emailVerifyChange(req: Request) throws -> Response {
        return responseFactory.makeSuccessResponse()
    }
}
