import SwiftUI
import Base
import Networking
import Domain

@MainActor @Observable
final class MembersListViewModel {
    enum Intent {
        case createInvitation
    }

    var toastMessage: String?
    var groupMembers: [Member] {
        group.members ?? []
    }

    let group: Domain.Group
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
            guard let tokens = Tokens() else {
                // TODO: handle error
                return
            }
            do {
                let response = try await backend.createGroupInvitationCode(
                    tokens: tokens,
                    id: group.id
                )
                let link = "https://rewindapp.ru/join/\(response.invitationCode)"
                router.navigateToAddMember(groupName: group.name, link: link)
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }
        }
    }
}
