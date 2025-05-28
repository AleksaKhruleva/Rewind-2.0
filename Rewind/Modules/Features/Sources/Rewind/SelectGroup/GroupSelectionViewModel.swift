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
    var currentGroup: Domain.CurrentGroupInfo? {
        get { GroupStorage.currentGroup }
        set {
            if let newValue {
                GroupStorage.set(newGroup: newValue)
            }
        }
    }
    var groupNameError: String?

    private(set) var shouldDismissSelf = false
    private(set) var groups: [Domain.Group]

    private let user: User
    private let backend: NetworkServiceProtocol
    private let jwtDecoder: JWTDecoder
    private weak var router: RewindRouter?

    init(user: User, groups: [Domain.Group], router: RewindRouter) {
        self.user = user
        self.groups = groups
        self.router = router
        backend = NetworkService()
        jwtDecoder = JWTDecoder()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .createGroup(name):
            if name.isEmpty || name.count < 3 {
                groupNameError = "The group name must contain\nat least three letters..."
                return
            }
            isLoading = true
            defer {
                isLoading = false
            }
            do {
                guard let tokens = Tokens() else {
                    // TODO: handle unauthorized
                    return
                }

                guard let userID = jwtDecoder.getUserId(from: tokens.accessToken) else {
                    return
                }

                let response = try await backend.createGroup(tokens: tokens, name: name)
                
                let members = [
                    Member(
                        id: userID,
                        name: user.name,
                        imageURL: user.imageURL,
                        isOwner: true,
                        isUser: true
                    )
                ]
                
                await ImageProvider.loadAndCacheImage(for: user.imageURL, .user)

                let group = Group(
                    id: response.groupID,
                    name: response.name,
                    ownerID: response.ownerID,
                    imageURL: response.imageURL,
                    createdAt: DateParser.parseISODate(response.createdAt),
                    members: members
                )

                GroupStorage.set(newGroup: group)

                isGroupCreationViewPresented = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.shouldDismissSelf = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self?.router?.navigateToGroup(group)
                    }
                }
            } catch {
                print(error)
                // TODO: handle error
            }
        }
    }
}
