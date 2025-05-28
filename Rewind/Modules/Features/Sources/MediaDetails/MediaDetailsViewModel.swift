import SwiftUI
import UIComponents
import Networking
import Domain
import Base

@MainActor @Observable
final class MediaDetailsViewModel {
    enum Intent {
        case deleteMedia(GalleryItem)
        case addTag(GalleryItem, String)
        case deleteTag(GalleryItem, String)

        case likeMedia(GalleryItem)
        case unlikeMedia(GalleryItem)
    }

    var showToast: (String) -> Void
    let backend: NetworkServiceProtocol

    init() {
        self.showToast = { _ in }
        self.backend = NetworkService()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
        switch intent {
        case let .deleteMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.deleteMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                    onSuccess()
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .addTag(galleryItem, tag):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.addTag(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id,
                        tag: tag
                    )
                    onSuccess()
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .deleteTag(galleryItem, tag):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.deleteTag(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id,
                        tag: tag
                    )
                    onSuccess()
                }
            } catch let httpError as HTTPError where httpError == .conflict {
                showToast("Your tags must be unique 🏷️")
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .likeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.likeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .unlikeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.unlikeMedia(
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
