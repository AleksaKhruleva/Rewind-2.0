import SwiftUI
import Base
import Networking
import Domain

@MainActor @Observable
final class MembersListViewModel {
    enum Intent {
        case createInvitation
        case deleteMember(Member)
        case loadGroupImage
    }

    var toastMessage: String?
    var groupMembers: [Member] {
        get { group.members ?? [] }
        set { group.members = newValue }
    }
    private(set) var isLoading = false
    private(set) var group: Domain.Group
    private(set) var progressMessage = ""
    private(set) var groupImage: UIImage = DomainAsset.groupPlaceholder.image

    let router: MembersListRouter
    private let backend: NetworkServiceProtocol

    init(group: Domain.Group, router: MembersListRouter) {
        self.group = group
        self.router = router
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .createInvitation:
            await createInvitation()

        case let .deleteMember(member):
            await deleteMember(member)
            
        case .loadGroupImage:
            await loadGroupImage()
        }
    }
    
    private func loadGroupImage() async {
        guard let currentGroup = GroupStorage.currentGroup else {
            // TODO: handle nil group
            return
        }
        let image = await ImageProvider.loadOrGetImage(
            for: currentGroup.imageURL, .group
        )
        await MainActor.run { [weak self] in
            self?.groupImage = image
        }
    }

    private func createInvitation() async {
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
            router.navigateToAddMember(groupName: group.name, link: link)
        } catch let error as HTTPError where error == .forbidden || error == .notFound {
            toastMessage = "You no longer have access to this group!"
            GroupStorage.clear()
            router.navigateToRewind()
        } catch {
            toastMessage = "Error: \(error). Try again later!"
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
                groupMembers.removeAll { $0.id == member.id }
                toastMessage = "\(member.name) have been successfully removed from the group!"
            }
        } catch let error as HTTPError where error == .forbidden || error == .notFound {
            toastMessage = "You no longer have access to this group!"
            GroupStorage.clear()
            router.navigateToRewind()
        } catch {
            toastMessage = "Error: \(error). Try again later!"
        }
    }
}
