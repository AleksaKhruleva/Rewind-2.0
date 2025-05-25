import XCTest
import Vapor

final class AuthenticationUITests: XCTestCase {
    func testRegistration() throws {
        let responseFactory = AuthenticationResponseFactory.make()
        let backend = try MockBackend(
            configuration: { routes in
                try routes.register(
                    collection: AuthenticationController.make(with: responseFactory)
                )
            }
        )

        let rewind = try launchAuthenticationRewind(mockBackend: backend)

        rewind.tapSignUpButton()
        rewind.inputEmail()
        rewind.inputCode()
        rewind.inputPassword()
        rewind.inputName()
    }

    func testLogin() throws {
        let responseFactory = AuthenticationResponseFactory.make()
        let backend = try MockBackend(
            configuration: { routes in
                try routes.register(
                    collection: AuthenticationController.make(with: responseFactory)
                )
            }
        )

        let rewind = try launchAuthenticationRewind(mockBackend: backend)

        rewind.tapSignInButton()
        rewind.inputEmail()
        rewind.inputPassword()
    }
}

extension XCTestCase {
    func launchAuthenticationRewind(
        mockBackend: MockBackend,
    ) throws -> AuthenticationRewindApplication {
        mockBackend.launch()
        let app = XCUIApplication()
        app.launchArguments = ["-useLocalhost", "-testingAuth"]
        app.launch()
        return AuthenticationRewindApplication(app: app, backend: mockBackend)
    }
}
