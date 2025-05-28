import SwiftUI
import UIComponents
import Networking
import Domain
import Base

@MainActor @Observable
final class MediaDetailsViewModel {
    enum Intent {
        case fetchMemory(Int)
        case deleteMedia
        case addTag(String)
        case deleteTag(String)

        case likeMedia
        case unlikeMedia
    }

    var galleryItem: GalleryItem?
    var tags: [MediaTag]
    var showToast: (String) -> Void
    let backend: NetworkServiceProtocol

    init() {
        self.showToast = { _ in }
        self.tags = []
        self.backend = NetworkService()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
        switch intent {
        case let .fetchMemory(memoryId):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    galleryItem = try await backend.getMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: memoryId
                    ).toGalleryItem()
                    tags = galleryItem?.tags.map { MediaTag(tag: $0) } ?? []
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .deleteMedia:
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = galleryItem?.id {
                    _ = try await backend.deleteMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId
                    )
                    onSuccess()
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .addTag(tag):
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = galleryItem?.id {
                    _ = try await backend.addTag(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId,
                        tag: tag
                    )
                    onSuccess()
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .deleteTag(tag):
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = galleryItem?.id {
                    _ = try await backend.deleteTag(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId,
                        tag: tag
                    )
                    onSuccess()
                }
            } catch let httpError as HTTPError where httpError == .conflict {
                showToast("Your tags must be unique 🏷️")
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .likeMedia:
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = galleryItem?.id {
                    _ = try await backend.likeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .unlikeMedia:
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = galleryItem?.id {
                    _ = try await backend.unlikeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId
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
