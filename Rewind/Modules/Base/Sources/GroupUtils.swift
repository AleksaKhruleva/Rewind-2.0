import Foundation
import Domain

public enum GroupUtils {
    public static func sortedGroups(from responses: [GroupResponse]) -> [Domain.Group] {
        var groups = responses
            .map { response in
                Domain.Group(
                        id: response.groupID,
                        name: response.name,
                        ownerID: response.ownerID,
                        imageURL: response.imageURL,
                        createdAt: DateParser.parseISODate(response.createdAt)
                    )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let currentGroupID = GroupStorage.currentGroup?.id {
            if let currentGroup = groups.first(where: { $0.id == currentGroupID }) {
                groups.removeAll { $0.id == currentGroupID }
                groups.insert(currentGroup, at: 0)
            }
        }

        return groups
    }

    public static func sortedGroups(_ groups: [Domain.Group]) -> [Domain.Group] {
        var sorted = groups.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let currentGroupID = GroupStorage.currentGroup?.id,
           let currentGroup = sorted.first(where: { $0.id == currentGroupID }) {
            sorted.removeAll { $0.id == currentGroupID }
            sorted.insert(currentGroup, at: 0)
        }

        return sorted
    }

    public static func sortedMembers(
        from responses: [GroupMemberResponse],
        groupOwnerID: Int,
        currentUserID: String
    ) -> [Member] {
        return responses
            .map { response in
                Member(
                    id: String(response.id),
                    name: response.name,
                    imageData: nil,
                    isOwner: response.id == groupOwnerID,
                    isUser: String(response.id) == currentUserID
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.isOwner, rhs.isOwner) {
                case (true, false): return true
                case (false, true): return false
                default:
                    switch (lhs.isUser, rhs.isUser) {
                    case (true, false): return true
                    case (false, true): return false
                    default:
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }
                }
            }
    }
}
