import SwiftUI
import Networking
import Base
import Domain
import UIComponents

@MainActor @Observable
final class GroupSettingsViewModel {
    enum Intent {
        case updateName(String)
        case leaveGroup
        case deleteGroup
    }

    var toastMessage: String?
    var groupNameError: String?
    var needNameInputView = false
    var isLoading = false
    private(set) var progressMessage = ""
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
            if newName.isEmpty || newName.count < 3 {
                groupNameError = "The group name must contain\nat least three letters..."
                return
            }
            progressMessage = "Updating the group name..."
            isLoading = true
            defer {
                isLoading = false
            }
            guard let tokens = Tokens() else {
                // TODO: handle unauthorized
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
                toastMessage = UIComponentsStrings.Account.Edit.Name.success
                isLoading = false
            } catch let error as HTTPError where error == .forbidden {
                toastMessage = "You no longer have access to this group!"
                GroupStorage.clear()
                router.navigateToRewind()
            } catch {
                toastMessage = "Error: \(error). Try again later!"
                isLoading = false
                needNameInputView = false
            }

        case .leaveGroup:
            progressMessage = "Removing you from the group..."
            isLoading = true
            defer {
                isLoading = false
            }
            guard let tokens = Tokens(),
                  let userID = JWTDecoder().getUserId(from: tokens.accessToken)
            else {
                // TODO: handle unauthorized
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
                } else {
                    toastMessage = "Couldn't remove you from the group. Try again later!"
                }
            } catch let error as HTTPError where error == .forbidden {
                toastMessage = "You no longer have access to this group!"
                GroupStorage.clear()
                router.navigateToRewind()
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }

        case .deleteGroup:
            progressMessage = "Deleting the group..."
            isLoading = true
            defer {
                isLoading = false
            }
            guard let tokens = Tokens() else {
                // TODO: handle unauthorized
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
                } else {
                    toastMessage = UIComponentsStrings.Toast.error
                }
            } catch let error as HTTPError where error == .forbidden {
                toastMessage = "You no longer have access to this group!"
                GroupStorage.clear()
                router.navigateToRewind()
            } catch {
                toastMessage = "Error: \(error). Try again later!"
            }
        }
    }
}
