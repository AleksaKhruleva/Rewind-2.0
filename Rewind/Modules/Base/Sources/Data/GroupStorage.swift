import Foundation
import Domain

public struct GroupStorage {
    @UserDefaultsCodable(key: "currentGroup", defaultValue: nil)
    public static var currentGroup: CurrentGroupInfo?

    public static func set(groupID: Int, name: String, imageData: Data?) {
        currentGroup = CurrentGroupInfo(
            id: groupID,
            name: name,
            imageData: imageData
        )
    }

    public static func set(newGroup: Domain.Group) {
        currentGroup = CurrentGroupInfo(
            id: newGroup.id,
            name: newGroup.name,
            imageData: newGroup.imageData
        )
    }

    public static func set(newGroup: CurrentGroupInfo) {
        currentGroup = newGroup
    }

    public static func clear() {
        currentGroup = nil
    }
}
