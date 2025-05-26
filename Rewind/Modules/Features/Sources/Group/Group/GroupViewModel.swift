import SwiftUI
import Domain
import Base
import Networking

@MainActor @Observable
final class GroupViewModel {
    enum Intent {
        case createInvitation
    }

    enum InvitationState {
        case ready
        case notReady
    }

    private(set) var invitationState = InvitationState.ready
    let group: Domain.Group
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
            do {
                guard let tokens = Tokens() else {
                    return
                }

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
                print(error)
                // TODO: handle error
            }
        }
    }
}
