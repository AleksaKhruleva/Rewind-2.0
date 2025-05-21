import SwiftUI

public struct RootView: View {
    @Bindable var router: AppRouter
    
    public init(router: AppRouter) {
        self.router = router
    }
    
    public var body: some View {
        ZStack {
            ForEach(Array(router.stack.enumerated()), id: \.element.id) { index, wrapper in
                let isBelowTop = index == router.stack.count - 2
                
                screen(for: wrapper.route)
                    .transition(transition(for: wrapper.transition))
                    .zIndex(Double(index))
                
                    .overlay {
                        if isBelowTop {
                            Color.black.opacity(0.2)
                                .ignoresSafeArea()
                                .transition(.opacity)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.stack)
    }
    
    // the same order of cases as in AppRouter.Route enum
    @ViewBuilder
    private func screen(for route: AppRouter.Route) -> some View {
        switch route {
        case .welcome: WelcomeView(router: AuthenticationRouter(appRouter: router))
            
        case let .email(flow): EmailInputView(flow: flow, router: AuthenticationRouter(appRouter: router))
        case let .code(email, registrationID): CodeInputView(router: AuthenticationRouter(appRouter: router), email: email, registrationID: registrationID)
        case let .password(flow, registrationID): PasswordInputView(flow: flow, router: AuthenticationRouter(appRouter: router), registrationID: registrationID)
        case let .name(email, password, registrationID): NameInputView(router: AuthenticationRouter(appRouter: router), email: email, password: password, registrationID: registrationID)
            
        case .rewind: RewindView(router: RewindRouter(appRouter: router))
        case .map: RewindsMap(router: router)
            
        case .account: AccountView(router: AccountRouter(appRouter: router))
        case .gallery: GalleryView(router: GalleryRouter(appRouter: router))
        case .quoteCreation: QuoteCreationView(router: router)
        case .mediasUploading: MediasUploadingView(router: router)
        case let .mediaDetails(image): MediaDetailsView(router: router, image: image)
            
        case .group: GroupView(router: GroupRouter(appRouter: router))
        case .groupSettings: GroupSettingsView(router: GroupSettingsRouter(appRouter: router))
        case let .addMember(groupName): AddMemberView(groupName: groupName, router: router)
        case let .memberDetails(member): MemberDetailsView(member: member, router: router)
        case .membersList: MembersListView(router: MembersListRouter(appRouter: router))
            
        case .rewindsStand: StandView(title: "You added 207 Rewinds", counterType: .rewinds, router: router)
        case .rollsStand: StandView(title: "You rolled 207 Rewinds", counterType: .rolls, router: router)
        }
    }
    
    private func transition(for style: AppRouter.TransitionStyle) -> AnyTransition {
        switch style {
        case .pushFromRight: return .move(edge: .trailing)
        case .pushFromLeft: return .move(edge: .leading)
        case .pushFromBottom: return .move(edge: .bottom)
        case .none: return .identity
        }
    }
}
