import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class GroupSettingsViewModel {
    enum Intent {
        case updateName(String)
        case leaveGroup
        case deleteGroup
    }

    var isLoading = false
    var progressMessage = ""
    var needNameInputView = false
    var toastMessage: String?
    private(set) var group: Domain.Group
    let router: GroupSettingsRouter

    private let backend: NetworkServiceProtocol

    init(group: Domain.Group, router: GroupSettingsRouter) {
        self.group = group
        self.router = router
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .updateName(newName):
            isLoading = true

            do {
                guard let tokens = Tokens() else {
                    // TODO: handle unauthorized
                    isLoading = false
                    return
                }

                let response = try await backend.updateGroupName(
                    tokens: tokens,
                    id: group.id,
                    name: newName
                )

                let newGroup = CurrentGroupInfo(id: response.groupID, name: response.name, imageData: nil)
                GroupStorage.set(newGroup: newGroup)
                group.name = response.name

                withAnimation(.easeInOut(duration: 0.3)) {
                    needNameInputView = false
                }

                try await Task.sleep(for: .milliseconds(300))
                toastMessage = "Name was successfully changed! ✍️"
            } catch {
                print(error)
                // TODO: handle error
            }

            isLoading = false
        case .leaveGroup:
            print("leave group")
        case .deleteGroup: break
            // TODO: finish later
        }
    }
}
