import Foundation
import XCTest

final class RewindTests: XCTestCase {
    func testRegistrationFlow() {
        let app = XCUIApplication()
        app.launch()
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.path == "/auth/register"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is not set.")
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// ✅ 2. Сам тест регистрации
final class RegistrationUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // Подделка сетевого запроса
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/register")

            // Проверяем тело запроса
            if let body = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                XCTAssertEqual(json["email"] as? String, "test@example.com")
            } else {
                XCTFail("Invalid body")
            }

            // Ответ
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            let responseData = """
            { "registrationid": "abc123" }
            """.data(using: .utf8)!

            return (response, responseData)
        }
    }

    func testRegistrationFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-useLocalhost"]
        app.launch()

        let registerButton = app.buttons["Sign up"]
        registerButton.tap()
        
        let emailField = app.textFields.firstMatch
        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        emailField.tap()
        emailField.typeText("test@example.com")

        // Нажать Enter на клавиатуре
        app.keyboards.buttons["done"].tap()

        // Ожидаем следующий экран
        let nextScreenLabel = app.staticTexts["nextScreenLabel"]
        XCTAssertTrue(nextScreenLabel.waitForExistence(timeout: 2))
    }
}
