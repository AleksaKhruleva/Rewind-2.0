import Vapor

struct AuthenticationController: RouteCollection {
    let responseFactory: AuthenticationResponseFactory
    
    static func make(with factory: AuthenticationResponseFactory) -> AuthenticationController {
        AuthenticationController(responseFactory: factory)
    }
    
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("verify-email", use: verify)
        auth.post("finish-register", use: finish)
        auth.post("login", use: login)
    }
    
    func register(req: Request) throws -> Response {
        return responseFactory.makeRegisterResponse()
    }
    
    func verify(req: Request) throws -> Response {
        return responseFactory.makeVerifyResponse()
    }
    
    func finish(req: Request) throws -> Response {
        return responseFactory.makeFinishResponse()
    }
    
    func login(req: Request) throws -> Response {
        return responseFactory.makeLoginResponse()
    }
}
