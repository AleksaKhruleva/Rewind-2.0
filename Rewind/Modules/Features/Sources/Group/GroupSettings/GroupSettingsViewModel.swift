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
            progressMessage = "Updating the group name..."
            isLoading = true

            guard let tokens = Tokens() else {
                // TODO: handle unauthorized
                isLoading = false
                return
            }

            do {
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
                isLoading = false
            } catch {
                toastMessage = "Error: \(error). Try again later!"
                isLoading = false
                needNameInputView = false
            }
        case .leaveGroup:
            progressMessage = "Removing you from the group..."
            isLoading = true

            guard let tokens = Tokens(),
                  let userID = JWTDecoder().getUserId(from: tokens.accessToken)
            else {
                // TODO: handle unauthorized
                isLoading = false
                return
            }

            do {
                let response = try await backend.deleteMemberFromGroup(
                    tokens: tokens,
                    groupID: group.id,
                    memberID: userID
                )

                if response.success {
                    GroupStorage.clear()
                    router.navigateToRewind()
                    isLoading = false
                } else {
                    toastMessage = "Couldn't remove you from the group. Try again later!"
                    isLoading = false
                }
            } catch {
                toastMessage = "Error: \(error). Try again later!"
                isLoading = false
            }
        case .deleteGroup:
            progressMessage = "Deleting the group..."
            isLoading = true

            guard let tokens = Tokens() else {
                // TODO: handle unauthorized
                isLoading = false
                return
            }

            do {
                let response = try await backend.deleteGroup(
                    tokens: tokens,
                    id: group.id
                )

                if response.success {
                    GroupStorage.clear()
                    router.navigateToRewind()
                    isLoading = true
                } else {
                    toastMessage = "Couldn't delete the group. Try again later!"
                    isLoading = false
                }
            } catch {
                toastMessage = "Error: \(error). Try again later!"
                isLoading = false
            }
        }
    }
}
