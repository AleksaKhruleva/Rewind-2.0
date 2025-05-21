import SwiftUI
import Domain

@MainActor
public final class MembersListRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToAddMember() {
        appRouter?.navigate(to: .addMember, with: .pushFromLeft)
    }
    
    func navigateToMemberDetails(_ member: Member) {
        appRouter?.navigate(to: .memberDetails(member), with: .pushFromLeft)
    }
    
    func dismiss() {
        appRouter?.pop()
    }
}
