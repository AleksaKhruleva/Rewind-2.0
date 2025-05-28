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
        case loadGroupImage
    }

    enum InvitationState {
        case ready
        case notReady
    }

    var group: Domain.Group
    var toastMessage: String?
    var shortGroupMembers: [Member] {
        group.members?.prefix(4).map { $0 } ?? []
    }
    private(set) var isGroupImageReady = true
    private(set) var groupImage: UIImage = DomainAsset.groupPlaceholder.image
    private(set) var progressMessage = ""
    private(set) var isLoading = false
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
            } catch let error as HTTPError where error == .forbidden || error == .notFound {
                toastMessage = "You no longer have access to this group!"
                GroupStorage.clear()
                router.navigateToRewind()
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }

        case let .deleteMember(member):
            await deleteMember(member)

        case .refreshGroupData:
            await refreshGroupData()

        case .loadGroupImage:
            await loadGroupImage()
        }
    }

    private func loadGroupImage() async {
        isGroupImageReady = false
        guard let currentGroup = GroupStorage.currentGroup else {
            // TODO: handle nil group
            return
        }
        let image = await ImageProvider.loadOrGetImage(
            for: currentGroup.imageURL, .group
        )
        await MainActor.run { [weak self] in
            self?.groupImage = image
            self?.isGroupImageReady = true
        }
    }

    private func deleteMember(_ member: Member) async {
        isLoading = true
        progressMessage = "Removing \(member.name) from the group..."
        defer {
            isLoading = false
        }
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
                toastMessage = "\(member.name) have been successfully removed from the group!"
            } else {
                toastMessage = UIComponentsStrings.Toast.error
            }
        } catch let error as HTTPError where error == .forbidden || error == .notFound {
            toastMessage = "You no longer have access to this group!"
            GroupStorage.clear()
            router.navigateToRewind()
        } catch {
            toastMessage = "Error: \(error). Try again later!"
        }
    }

    private func refreshGroupData() async {
        isLoading = true
        defer {
            isLoading = false
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

            let members = GroupUtils.sortedMembers(
                from: response.members,
                groupOwnerID: response.group.ownerID,
                currentUserID: userID
            )

            let currentGroup = Domain.Group(
                id: currentGroupID,
                name: response.group.name,
                ownerID: response.group.ownerID,
                imageURL: response.group.imageURL,
                createdAt: DateParser.parseISODate(response.group.createdAt), members: members
            )

            self.group = currentGroup
            toastMessage = "Group data has been successfully updated!"
        } catch let error as HTTPError where error == .forbidden || error == .notFound {
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
