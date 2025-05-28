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

        case toggleTrackPlaying
        case killPlayer
    }

    var isTrackPlaying = false
    var galleryItem: GalleryItem?
    var tags: [MediaTag]
    var showToast: (String) -> Void
    let backend: NetworkServiceProtocol
    let soundCloudBackend: SoundCloudServiceProtocol
    let audioManager: AudioPlayerManager

    init() {
        self.showToast = { _ in }
        self.tags = []
        self.backend = NetworkService()
        self.soundCloudBackend = SoundCloudNetworkService()
        self.audioManager = AudioPlayerManager.shared
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
                    if let trackInfo = galleryItem?.memory.trackInfo {
                        do {
                            let response = try await soundCloudBackend.fetchTrack(by: trackInfo.id)
                            var lightTrack = response.toLightTrack(with: trackInfo)

                            if let streamURL = try await soundCloudBackend.fetchStreamURL(for: lightTrack) {
                                lightTrack.streamURL = streamURL
                            } else {
                                showToast("Couldn't get track stream URL.")
                            }

                            galleryItem?.memory.lightTrack = lightTrack
                        } catch {
                            showToast("Couldn't download music :( Try again later!")
                        }
                    }
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
        case .toggleTrackPlaying:
            if !isTrackPlaying {
                guard let track = galleryItem?.memory.lightTrack else {
                    return
                }
                guard let streamURL = track.streamURL else {
                    return
                }
                audioManager.load(url: streamURL)
                audioManager.play(
                    from: track.startTime,
                    duration: track.duration,
                    fullDurationMillis: track.fullDuration,
                    loop: true
                ) { [weak self] isPlaying in
                    self?.isTrackPlaying = isPlaying
                }
            } else {
                isTrackPlaying = false
                audioManager.stop()
            }
        case .killPlayer:
            isTrackPlaying = false
            audioManager.cleanup()
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
