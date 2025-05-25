import XCTest
import Vapor

final class UserEditingUITests: XCTestCase {
    func testNameEditing() throws {
        let responseFactory = UserEditingResponseFactory.make()
        let backend = try MockBackend(
            configuration: { routes in
                try routes.register(
                    collection: UserEditingController.make(with: responseFactory)
                )
            }
        )

        let rewind = try launchUserEditingRewind(mockBackend: backend)

        rewind.tapAccountButton()
        rewind.tapChangeNameButton()
        rewind.inputName()
    }

    func testPasswordEditing() throws {
        let responseFactory = UserEditingResponseFactory.make()
        let backend = try MockBackend(
            configuration: { routes in
                try routes.register(
                    collection: UserEditingController.make(with: responseFactory)
                )
            }
        )

        let rewind = try launchUserEditingRewind(mockBackend: backend)

        rewind.tapAccountButton()
        rewind.tapChangePasswordButton()
        rewind.inputPasswordChangeCode()
        rewind.inputPasswordChangePassowrd()
    }

    func testEmailEditing() throws {
        let responseFactory = UserEditingResponseFactory.make()
        let backend = try MockBackend(
            configuration: { routes in
                try routes.register(
                    collection: UserEditingController.make(with: responseFactory)
                )
            }
        )

        let rewind = try launchUserEditingRewind(mockBackend: backend)

        rewind.tapAccountButton()
        rewind.tapChangeEmailButton()
        rewind.inputEmailChangePassowrd()
        rewind.inputEmail()
        rewind.inputEmailChangeCode()
    }
}

extension XCTestCase {
    func launchUserEditingRewind(
        mockBackend: MockBackend,
    ) throws -> UserEditingRewindApplication {
        mockBackend.launch()
        let app = XCUIApplication()
        app.launchArguments = ["-useLocalhost", "-fakeTokens"]
        app.launch()
        return UserEditingRewindApplication(app: app, backend: mockBackend)
    }
}
