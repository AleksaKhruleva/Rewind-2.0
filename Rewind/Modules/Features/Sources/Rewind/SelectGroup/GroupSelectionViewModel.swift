import SwiftUI
import Base
import Networking
import Domain

@MainActor @Observable
final class GroupSelectionViewModel {
    enum Intent {
        case createGroup(String)
    }

    var isLoading = false
    var isGroupCreationViewPresented = false
    var currentGroupID: Int? {
        GroupStorage.currentGroup?.id
    }

    private(set) var shouldDismissSelf = false
    private(set) var groups: [Domain.Group]

    private let backend: NetworkServiceProtocol
    private let jwtDecoder: JWTDecoder
    private weak var router: RewindRouter?

    init(groups: [Domain.Group], router: RewindRouter) {
        self.groups = groups
        self.router = router
        backend = NetworkService()
        jwtDecoder = JWTDecoder()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .createGroup(name):
            isLoading = true
            do {
                guard let accessToken = KeychainService.shared.read(for: .accessToken),
                      let userID = jwtDecoder.getUserId(from: accessToken),
                      let user = UserStorage.currentUser,
                      let tokens = Tokens()
                else {
                    // TODO: handle error
                    isLoading = false
                    return
                }

                let response = try await backend.createGroup(tokens: tokens, name: name)

                let group = Group(
                    id: response.groupID,
                    name: response.name,
                    ownerID: response.ownerID,
                    members: [
                        Member(
                            id: userID,
                            name: user.name,
                            imageData: user.imageData,
                            isOwner: true,
                            isUser: true
                        )
                    ],
                    createdAt: DateParser.parseISODate(response.createdAt)
                )

                GroupStorage.set(groupID: group.id, imageData: group.imageData)

                isGroupCreationViewPresented = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.shouldDismissSelf = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self?.router?.navigateToGroup(group)
                    }
                }
            } catch {
                isLoading = false
                // TODO: handle error
            }
        }
    }
}
