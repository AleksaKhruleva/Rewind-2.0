import SwiftUI
import UIComponents
import Networking
import Domain
import Base

@MainActor @Observable
final class MediaDetailsViewModel {
    enum Intent {
        case deleteMedia(GalleryItem)
    }

    var showToast: (String) -> Void
    let backend: NetworkServiceProtocol

    init() {
        self.showToast = { _ in }
        self.backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .deleteMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.deleteMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
