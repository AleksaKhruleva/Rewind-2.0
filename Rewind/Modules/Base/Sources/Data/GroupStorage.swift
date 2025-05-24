import Foundation
import Domain

public struct GroupStorage {
    @UserDefaultsCodable(key: "currentGroup", defaultValue: nil)
    public static var currentGroup: CurrentGroupInfo?

    public static func set(groupID: Int, imageData: Data?) {
        currentGroup = CurrentGroupInfo(id: groupID, imageData: imageData)
    }

    public static func clear() {
        currentGroup = nil
    }
}
