import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class LinkProcessingViewModel {
    private weak var router: AppRouter?
    private let backend: NetworkServiceProtocol
    private let url: URL
    private let dismiss: (String) -> Void

    init(url: URL, router: AppRouter, dismiss: @escaping (String) -> Void) {
        self.url = url
        self.router = router
        self.dismiss = dismiss
        backend = NetworkService()
    }

    func addUserToGroup() async {
        do {
            guard let code = extractJoinCode(from: url),
                  let tokens = Tokens(),
                  let userID = JWTDecoder().getUserId(
                    from: tokens.accessToken
                  )
            else {
                // TODO: handle unauthorized
                return
            }

            let responseAddUser = try await backend.addUserToGroup(
                tokens: tokens,
                invitationCode: code
            )

            let responseGroupDetails = try await backend.fetchFullGroupDetails(
                tokens: tokens,
                id: responseAddUser.groupID
            )

            let members = GroupUtils.sortedMembers(
                from: responseGroupDetails.members,
                groupOwnerID: responseGroupDetails.group.ownerID,
                currentUserID: userID
            )

            await withTaskGroup(of: Void.self) { group in
                for member in members {
                    group.addTask {
                        await ImageProvider
                            .loadAndCacheImage(for: member.imageURL, .user)
                    }
                }
            }

            let currentGroup = Domain.Group(
                id: responseGroupDetails.group.groupID,
                name: responseGroupDetails.group.name,
                ownerID: responseGroupDetails.group.ownerID,
                imageURL: responseGroupDetails.group.imageURL,
                createdAt: DateParser.parseISODate(responseGroupDetails.group.createdAt),
                members: members
            )

            GroupStorage.set(newGroup: currentGroup)

            dismiss("You have been successfully added to the group!")
            router?.navigate(to: .group(currentGroup), with: .pushFromLeft)
        } catch let error as HTTPError where error == .conflict {
            dismiss("You are already a member of this group!")
        } catch let error as HTTPError where error == .notFound {
            dismiss("The group you're trying to join doesn't exist!")
        } catch {
            dismiss("Error: \(error). Try again later!")
        }
    }

    private func extractJoinCode(from url: URL) -> String? {
        let components = url.pathComponents
        if let index = components.firstIndex(of: "join"),
           components.indices.contains(index + 1) {
            return components[index + 1]
        }
        return nil
    }
}
