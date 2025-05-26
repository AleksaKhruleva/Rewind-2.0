import SwiftUI
import Domain

@MainActor
public final class MembersListRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToAddMember(groupName: String, link: String) {
        appRouter?.navigate(to: .addMember(groupName, link), with: .pushFromLeft)
    }

    func navigateToMemberDetails(_ member: Member) {
        appRouter?.navigate(to: .memberDetails(member), with: .pushFromLeft)
    }

    func dismiss() {
        appRouter?.pop()
    }
}
