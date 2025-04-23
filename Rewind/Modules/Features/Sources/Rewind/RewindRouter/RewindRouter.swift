import SwiftUI

@Observable
final class RewindRouter {
    enum Route: Hashable {
        case mediaDetails(UIImage)
        case account
        case gallery
    }
    
    var path = NavigationPath()
    
    func navigateToMediaDetails(image: UIImage) {
        path.append(Route.mediaDetails(image))
    }
    
    func navigateToAccount() {
        path.append(Route.account)
    }
    
    func navigateToGallery() {
        path.append(Route.gallery)
    }
    
    func popBack() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
