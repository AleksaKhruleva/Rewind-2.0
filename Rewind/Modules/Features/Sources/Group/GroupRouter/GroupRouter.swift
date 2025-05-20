import SwiftUI

@MainActor
public final class GroupRouter {
    private weak var appRouter: AppRouter?
    
    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    func navigateToGroupSettings() {
        appRouter?.navigate(to: .groupSettings, with: .pushFromLeft)
    }
    
    func navigateToAddMember() {
        appRouter?.navigate(to: .addMember, with: .pushFromLeft)
    }
    
    func navigateToMemberDetails() {
        appRouter?.navigate(to: .memberDetails, with: .pushFromLeft)
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
