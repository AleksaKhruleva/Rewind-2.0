import Networking
import Domain
import SwiftUI
import Base
import UIComponents

@MainActor @Observable
final class NameInputViewModel {
    enum Intent {
        case submitName(String)
    }
    
    enum NameState: Equatable {
        case loading
        case empty
        case error(NameError)
        case ready
    }
    
    enum NameError: Error {
        case responseError
        
        var errorDescription: String {
            switch self {
            case .responseError:
                return "Something went worng,\nplease try again"
            }
        }
    }
    
    var state: NameState = .empty
    let router: AuthenticationRouter
    
    private let password: String
    private let registrationID: String
    private let backend: NetworkServiceProtocol
    
    init(router: AuthenticationRouter, password: String, registrationID: String) {
        self.router = router
        self.password = password
        self.registrationID = registrationID
        backend = NetworkService()
    }
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .submitName(name):
            animateState(to: .loading)
            do {
                let response = try await backend.finishRegister(password: password, registrationID: registrationID, username: name)
                animateState(to: .ready)
                KeychainService.shared.save(response.accessToken, for: .accessToken)
                KeychainService.shared.save(response.refreshToken, for: .refreshToken)
            } catch {
                animateState(to: .error(.responseError))
            }
            
            if state == .ready {
                router.navigateToRewind()
            }
        }
    }
    
    func animateState(to state: NameState) {
        withAnimation(.spring(response: 0.2)) { self.state = state }
    }
}
