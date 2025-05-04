import XCTest
import AccessibilitySupport

struct AuthenticationRewindApplication {
    private var app: XCUIApplication
    var backend: MockBackend
    
    init(app: XCUIApplication, backend: MockBackend) {
        self.app = app
        self.backend = backend
    }
    
    func tapSignUpButton() {
        self(.signup).tap()
    }
    
    func tapSignInButton() {
        self(.signin).tap()
    }
    
    func inputEmail() {
        XCTAssertTrue(self(.email).waitForExistence(timeout: 1))
        self(.email).typeText("test@example.com")
        submitInput()
    }
    
    func inputCode() {
        for i in 0...3 {
            let digit = self(.code(i))
            XCTAssertTrue(digit.waitForExistence(timeout: 0.2))
            digit.tap()
            digit.typeText(String(i))
        }
    }
    
    func inputPassword() {
        XCTAssertTrue(self(.password).waitForExistence(timeout: 1))
        self(.password).typeText("password")
        submitInput()
    }
    
    func inputName() {
        XCTAssertTrue(self(.name).waitForExistence(timeout: 1))
        self(.name).typeText("name")
        submitInput()
    }
    
    func submitInput() {
        app.keyboards.buttons["done"].tap()
    }
    
    private func callAsFunction(_ element: RewindElement.Auth.Input) -> XCUIElement {
        app.authElement(.auth(.input(element)))
    }
    
    private func callAsFunction(_ element: RewindElement.Auth.Button) -> XCUIElement {
        app.authElement(.auth(.button(element)))
    }
}

extension XCUIElement {
    fileprivate func authElement(_ element: RewindElement) -> XCUIElement {
        switch element {
        case let .auth(auth):
            switch auth {
            case .button:
                buttons[element.accessibilityID]
            case let .input(input):
                switch input {
                case .email, .name, .code: textFields[element.accessibilityID]
                case .password: secureTextFields[element.accessibilityID]
                }
            }
        }
    }
}
