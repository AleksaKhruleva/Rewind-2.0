import XCTest
import AccessibilitySupport

struct UserEditingRewindApplication {
    private var app: XCUIApplication
    var backend: MockBackend

    init(app: XCUIApplication, backend: MockBackend) {
        self.app = app
        self.backend = backend
    }

    func tapAccountButton() {
        self(.account).tap()
    }

    func tapChangeImageButton() {
        self(.editImage).tap()
    }

    func tapSetImageButton() {
        self(.editImageDialog(.set)).tap()
    }

    func tapChangeNameButton() {
        self(.editName).tap()
    }

    func inputName() {
        XCTAssertTrue(self(.name(.name)).waitForExistence(timeout: 1))
        self(.name(.name)).typeText("new_cool_name")
        submitInput()
    }

    func tapChangePasswordButton() {
        self(.editPassword).tap()
    }

    func inputPasswordChangeCode() {
        for digitIndex in 0...3 {
            let digit = self(.password(.code(digitIndex)))
            XCTAssertTrue(digit.waitForExistence(timeout: 0.2))
            digit.tap()
            digit.typeText(String(digitIndex))
        }
    }

    func inputPasswordChangePassowrd() {
        XCTAssertTrue(self(.password(.password)).waitForExistence(timeout: 1))
        self(.password(.password)).typeText("new_cool_password")
        submitInput()
    }

    func tapChangeEmailButton() {
        self(.editEmail).tap()
    }

    func inputEmailChangePassowrd() {
        XCTAssertTrue(self(.email(.password)).waitForExistence(timeout: 1))
        self(.email(.password)).typeText("new_cool_password")
        submitInput()
    }

    func inputEmail() {
        XCTAssertTrue(self(.email(.email)).waitForExistence(timeout: 1))
        self(.email(.email)).typeText("new_cool_email@email.com")
        submitInput()
    }

    func inputEmailChangeCode() {
        for digitIndex in 0...3 {
            let digit = self(.email(.code(digitIndex)))
            XCTAssertTrue(digit.waitForExistence(timeout: 0.2))
            digit.tap()
            digit.typeText(String(digitIndex))
        }
    }

    func submitInput() {
        app.keyboards.buttons["done"].tap()
    }

    private func callAsFunction(_ element: RewindElement.Rewind.Button) -> XCUIElement {
        app.userEditingElement(.rewind(.button(element)))
    }

    private func callAsFunction(_ element: RewindElement.Account.Button) -> XCUIElement {
        app.userEditingElement(.account(.button(element)))
    }

    private func callAsFunction(_ element: RewindElement.Account.EditFlow) -> XCUIElement {
        app.userEditingElement(.account(.editFlow(element)))
    }
}

extension XCUIElement {
    fileprivate var photo: XCUIElement {
      let predicate = NSPredicate(format: "label CONTAINS[c] 'Photo'")
      return images.containing(predicate).firstMatch
    }

    fileprivate func userEditingElement(_ element: RewindElement) -> XCUIElement {
        switch element {
        case let .account(account):
            switch account {
            case .button: buttons[element.accessibilityID]
            case let .editFlow(editFlow):
                switch editFlow {
                case .email(.password), .password(.password):
                    secureTextFields[element.accessibilityID]
                default:
                    textFields[element.accessibilityID]
                }
            }
        case let .rewind(rewind):
            switch rewind {
            case .button: buttons[element.accessibilityID]
            }
        case .auth:
            firstMatch
        }
    }
}
