import SwiftUI
import Domain
import Base
import Networking
import UIComponents

@MainActor @Observable
final class GroupViewModel {
    enum Intent {
        case createInvitation
        case deleteMember(Member)
        case refreshGroupData
    }

    enum InvitationState {
        case ready
        case notReady
    }

    var refreshMessage = "Updating group data..."
    var isRefreshing = false
    var group: Domain.Group
    var toastMessage: String?

    var shortGroupMembers: [Member] {
        group.members?.prefix(4).map { $0 } ?? []
    }

    private(set) var invitationState = InvitationState.ready

    let router: GroupRouter

    private let backend: NetworkServiceProtocol

    init(group: Domain.Group, router: GroupRouter) {
        self.group = group
        self.router = router
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .createInvitation:
            guard let tokens = Tokens() else {
                // TODO: handle unauthorized
                return
            }
            do {
                let response = try await backend.createGroupInvitationCode(
                    tokens: tokens,
                    id: group.id
                )
                let link = "https://rewindapp.ru/join/\(response.invitationCode)"
                router
                    .navigateToAddMember(
                        groupName: group.name,
                        link: link
                    )
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }
        case let .deleteMember(member):
            guard let tokens = Tokens() else {
                // TODO: handle anuthorized
                return
            }
            do {
                let response = try await backend.deleteMemberFromGroup(
                    tokens: tokens,
                    groupID: group.id,
                    memberID: member.id
                )
                if response.success {
                    group.members?.removeAll { $0.id == member.id }
                    toastMessage = "\(member.name) have been successfully removed from the group"
                }
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }
        case .refreshGroupData:
            await refreshGroupData()
        }
    }

    private func refreshGroupData() async {
        isRefreshing = true

        defer {
            isRefreshing = false
        }

        guard let currentGroupID = GroupStorage.currentGroup?.id,
              let tokens = Tokens(),
              let userID = JWTDecoder().getUserId(from: tokens.accessToken)
        else {
            // TODO: handle unauthorized
            return
        }

        do {
            let response = try await backend.fetchFullGroupDetails(
                tokens: tokens,
                id: group.id
            )

            let members = sortedMembers(
                from: response.members,
                groupOwnerID: response.group.ownerID,
                currentUserID: userID
            )

            let currentGroup = Domain.Group(
                id: currentGroupID,
                name: response.group.name,
                ownerID: response.group.ownerID,
                members: members,
                createdAt: DateParser.parseISODate(response.group.createdAt)
            )

            self.group = currentGroup
            toastMessage = "Group data has been successfully updated!"
        } catch let error as HTTPError where error == .forbidden {
            toastMessage = "You no longer have access to this group!"
            GroupStorage.clear()
            router.navigateToRewind()
        } catch {
            toastMessage = UIComponentsStrings.Toast.error
        }
    }

    private func sortedMembers(
        from responses: [GroupMemberResponse],
        groupOwnerID: Int,
        currentUserID: String
    ) -> [Member] {
        let members = responses.map { response in
            Member(
                id: String(response.id),
                name: response.name,
                imageData: nil,
                isOwner: response.id == groupOwnerID,
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
