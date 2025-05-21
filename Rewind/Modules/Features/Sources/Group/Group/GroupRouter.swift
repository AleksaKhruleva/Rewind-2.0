import SwiftUI
import Domain

@MainActor
public final class GroupRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToGroupSettings() {
        appRouter?.navigate(to: .groupSettings, with: .pushFromLeft)
    }
    
    func navigateToAddMember(groupName: String) {
        appRouter?.navigate(to: .addMember(groupName), with: .pushFromLeft)
    }
    
    func navigateToMemberDetails(_ member: Member) {
        appRouter?.navigate(to: .memberDetails(member), with: .pushFromLeft)
    }
    
    func navigateToMembersList() {
        appRouter?.navigate(to: .membersList, with: .pushFromLeft)
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
