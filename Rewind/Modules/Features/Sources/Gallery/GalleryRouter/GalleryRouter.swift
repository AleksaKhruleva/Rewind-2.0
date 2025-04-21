import Foundation
import SwiftUI

@Observable
final class GalleryRouter {
    enum GalleryRoute: Hashable {
        case mediaDetails(UIImage)
    }
    
    var path = NavigationPath()
    
    func navigateToMediaDetails(image: UIImage) {
        path.append(GalleryRoute.mediaDetails(image))
    }
    
    func popBack() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
