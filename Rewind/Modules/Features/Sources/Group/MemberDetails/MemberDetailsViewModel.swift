import SwiftUI
import Domain
import Base
import Networking

struct UserActivity {
    let memoriesAddedCount: Int
    let memoriesViewedCount: Int
    let invitedMembersCount: Int
    let daysSince: Int
}

@MainActor @Observable
final class MemberDetailsViewModel {
    enum Intent {
        case fetchUser
    }

    var activity: UserActivity?

    let member: Member
    private let backend = NetworkService()

    init(member: Member) {
        self.member = member
    }

    func dispatch(_ intent: Intent, onFailure: () -> Void = {}) async {
        switch intent {
        case .fetchUser:
            do {
                if let tokens = Tokens() {
                    let response = try await backend.user(tokens: tokens, userId: member.id)
                    activity = UserActivity(
                        memoriesAddedCount: response.memoriesAdded,
                        memoriesViewedCount: response.memoriesViewed,
                        invitedMembersCount: response.invitedMembers,
                        daysSince: DateParser.parseISODate(response.createdAt).daysSince
                    )
                }
            } catch {
                onFailure()
            }
        }
    }
}
