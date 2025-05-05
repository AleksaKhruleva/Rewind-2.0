import Domain

public struct UserStorage {
    @UserDefaultsCodable(key: "currentUser", defaultValue: nil)
    public static var currentUser: User?
    
    public static func clear() {
        currentUser = nil
    }
}
