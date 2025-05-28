import Foundation
import Domain

public struct GroupStorage {
    @UserDefaultsCodable(key: "currentGroup", defaultValue: nil)
    public static var currentGroup: CurrentGroupInfo?

    public static func set(groupID: Int, name: String, imageURL: String) {
        currentGroup = CurrentGroupInfo(
            id: groupID,
            name: name,
            imageURL: imageURL
        )
    }

    public static func set(newGroup: Domain.Group) {
        currentGroup = CurrentGroupInfo(
            id: newGroup.id,
            name: newGroup.name,
            imageURL: newGroup.imageURL
        )
    }

    public static func set(newGroup: CurrentGroupInfo) {
        currentGroup = newGroup
    }

    public static func clear() {
        currentGroup = nil
    }
}
