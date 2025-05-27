import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class LinkProcessingViewModel {
    private weak var router: AppRouter?
    private let backend: NetworkServiceProtocol
    private let url: URL
    private let dismiss: (String) -> Void

    init(url: URL, router: AppRouter, dismiss: @escaping (String) -> Void) {
        self.url = url
        self.router = router
        self.dismiss = dismiss
        backend = NetworkService()
    }

    func addUserToGroup() async {
        do {
            guard let code = extractJoinCode(from: url),
                  let tokens = Tokens(),
                  let userID = JWTDecoder().getUserId(
                    from: tokens.accessToken
                  )
            else {
                // TODO: handle unauthorized
                return
            }

            let responseAddUser = try await backend.addUserToGroup(
                tokens: tokens,
                invitationCode: code
            )

            let responseGroupDetails = try await backend.fetchFullGroupDetails(
                tokens: tokens,
                id: responseAddUser.groupID
            )

            let members = sortedMembers(
                from: responseGroupDetails.members,
                currentUserID: userID
            )

            let currentGroup = Domain.Group(
                id: responseGroupDetails.group.groupID,
                name: responseGroupDetails.group.name,
                ownerID: responseGroupDetails.group.ownerID,
                members: members,
                createdAt: DateParser.parseISODate(responseGroupDetails.group.createdAt)
            )

            GroupStorage.set(newGroup: currentGroup)

            dismiss("You have been successfully added to the group")
            router?.navigate(to: .group(currentGroup), with: .pushFromLeft)
        } catch {
            print(error, error.localizedDescription)
            dismiss("\(error). Try again later")
        }
    }

    private func extractJoinCode(from url: URL) -> String? {
        let components = url.pathComponents
        if let index = components.firstIndex(of: "join"),
           components.indices.contains(index + 1) {
            return components[index + 1]
        }
        return nil
    }

    private func sortedGroups(from responses: [GroupResponse]) -> [Domain.Group] {
        var groups = responses
            .map { response in
                Group(
                    id: response.groupID,
                    name: response.name
                    // imageData: ...
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

    private func sortedMembers(from responses: [GroupMemberResponse], currentUserID: String) -> [Member] {
        let members = responses.map { response in
            Member(
                id: String(response.id),
                name: response.name,
                imageData: nil,
                isOwner: response.isOwner,
                isUser: String(response.id) == currentUserID
            )
        }

        return members.sorted { lhs, rhs in
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
