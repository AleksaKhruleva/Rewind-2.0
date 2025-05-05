import Foundation

@propertyWrapper
public struct UserDefaultsCodable<T: Codable> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    public init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    public var wrappedValue: T {
        get {
            guard let data = storage.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            storage.set(data, forKey: key)
        }
    }
}
