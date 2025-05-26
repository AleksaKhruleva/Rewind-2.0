import SwiftUI
import Domain

@MainActor
public final class GroupRouter {
    private weak var appRouter: AppRouter?

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func navigateToGroupSettings(_ group: Domain.Group) {
        appRouter?.navigate(to: .groupSettings(group), with: .pushFromLeft)
    }

    func navigateToAddMember(groupName: String, link: String) {
        appRouter?.navigate(to: .addMember(groupName, link), with: .pushFromLeft)
    }

    func navigateToMemberDetails(_ member: Member) {
        appRouter?.navigate(to: .memberDetails(member), with: .pushFromLeft)
    }

    func navigateToMembersList(_ group: Domain.Group) {
        appRouter?.navigate(to: .membersList(group), with: .pushFromLeft)
    }

    func navigateToRewindsStand() {
        appRouter?.navigate(to: .rewindsStand, with: .pushFromLeft)
    }

    func navigateToRollsStand() {
        appRouter?.navigate(to: .rollsStand, with: .pushFromLeft)
    }

    func navigateToGallery() {
        appRouter?.navigate(to: .gallery, with: .pushFromBottom)
    }

    func dismiss() {
        appRouter?.pop()
    }
}
