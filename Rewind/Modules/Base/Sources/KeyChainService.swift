import Foundation
import Security

public struct Tokens {
    public let accessToken: String
    public let refreshToken: String
    public init?() {
        guard let accessToken = KeychainService.shared.read(for: .accessToken),
              let refreshToken = KeychainService.shared.read(for: .refreshToken) else { return nil }
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public final class KeychainService {
    public static let shared = KeychainService()

    private init() {}

    public enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    @discardableResult
    public func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // удаляем старое значение перед сохранением
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func read(for key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let result = String(data: data, encoding: .utf8) else {
            return nil
        }

        return result
    }

    @discardableResult
    public func delete(for key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    @discardableResult
    public func clearAll() -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
