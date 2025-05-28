// swiftline:disable type_body_length
import SwiftUI

// удалить позже
import UIComponents

import Networking
import Base
import Domain

@MainActor @Observable
final class RewindViewModel {
    enum Intent {
        case fetchUser
        case toggleTrackPlaying
        case showNextMediaItem
        case fetchGroups
        case openGroup
        case selectedNewGroup(Domain.Group)
        case loadAvatars

        case fetchGallery
        case fetchRandomGalleryItems

        case likeMedia(GalleryItem)
        case unlikeMedia(GalleryItem)
    }

    enum UserGroupsState {
        case ready
        case notReady
    }

    enum CurrentGroupState {
        case ready
        case notReady
    }

    var showToast: (String) -> Void
    var isTrackPlaying = false
    var rolls = 0
    var groupImage: UIImage?
    var groupGallery = [GalleryItem]()
    var userImage: UIImage?
    private(set) var groups = [Domain.Group]()
    private(set) var userGroupsState = UserGroupsState.notReady
    private(set) var currentGroupState = CurrentGroupState.ready
    var currentGalleryItem: GalleryItem?
    let router: RewindRouter

    var fetchedUser: User?
    var user: User {
        get {
            guard let fetchedUser else {
                //                router.navigateToWelcome() // TODO: return when routing is ready
                return User(name: "", email: "", imageURL: "")
            }
            return fetchedUser
        }
        set {
            fetchedUser = newValue
        }
    }

    private let backend: NetworkServiceProtocol
    private let jwtDecoder: JWTDecoder
    private let audioManager: AudioPlayerManager
    private var galleryItemsStack = [GalleryItem]()

    init(router: RewindRouter) {
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
        jwtDecoder = JWTDecoder()
        audioManager = AudioPlayerManager.shared
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .fetchUser:
            do {
                guard let tokens = Tokens() else {
                    // router.navigateToWelcome() // TODO: return when routing is ready
                    return
                }
                let response = try await backend.user(tokens: tokens)
                user = response.toUser()
            } catch {
                showToast("\(error.localizedDescription) 😨")
            }
        case .fetchGallery:
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.getMedias(tokens: tokens, groupId: groupId)
                    withAnimation(.easeInOut(duration: 0.1)) {
                        groupGallery = response.memories?.map {
                            return $0.toGalleryItem()
                        }.shuffled() ?? []
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .fetchRandomGalleryItems:
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.getRandomMedias(
                        tokens: tokens,
                        groupId: groupId,
                        mediaType: "",
                        limit: 10
                    )
                    withAnimation(.easeInOut(duration: 0.1)) {
                        galleryItemsStack.append(contentsOf: response.memories?.map {
                            $0.toGalleryItem()
                        }.shuffled() ?? [])
                        if currentGalleryItem == nil {
                            currentGalleryItem = galleryItemsStack.first
                        }
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .toggleTrackPlaying:
            if let currentGalleryItem, !isTrackPlaying {
                guard let streamURL = currentGalleryItem.memory.lightTrack?.streamURL else {
                    return
                }
                audioManager.load(url: streamURL)
                audioManager.play(from: .zero, duration: 15.0) { [weak self] isPlaying in
                    self?.isTrackPlaying = isPlaying
                }
            } else {
                stopPlayer()
            }
        case .showNextMediaItem:
            stopPlayer()
            rolls += 1
            if let galleryItem = galleryItemsStack.popLast() {
                currentGalleryItem = galleryItem
            }
            if galleryItemsStack.count <= 2 {
                await dispatch(.fetchRandomGalleryItems)
            }
        case .fetchGroups:
            userGroupsState = .notReady
            defer {
                userGroupsState = .ready
            }
            do {
                guard let tokens = Tokens() else { return }
                let responses = try await backend.fetchGroups(tokens: tokens)
                let sorted = GroupUtils.sortedGroups(from: responses)
                await withTaskGroup(of: Void.self) { group in
                    for groupItem in sorted {
                        group.addTask {
                            await ImageProvider.loadAndCacheImage(for: groupItem.imageURL, .group)
                        }
                    }
                }
                groups = sorted
                if let currentGroupId = GroupStorage.currentGroup?.id {
                    if let updatedGroup = groups.first(where: { $0.id == currentGroupId }) {
                        GroupStorage.set(newGroup: updatedGroup)
                    } else {
                        GroupStorage.currentGroup = nil
                        showToast("You no longer have access to the currently selected group!")
                    }
                }
            } catch {
                groups = []
                showToast(UIComponentsStrings.Toast.error)
            }
        case .openGroup:
            withAnimation { currentGroupState = .notReady }
            defer {
                withAnimation { currentGroupState = .ready }
            }
            do {
                guard let currentGroupID = GroupStorage.currentGroup?.id,
                      let tokens = Tokens(),
                      let userID = jwtDecoder.getUserId(from: tokens.accessToken)
                else {
                    // TODO: throw error
                    return
                }

                let response = try await backend.fetchFullGroupDetails(
                    tokens: tokens,
                    id: currentGroupID
                )

                let members = GroupUtils.sortedMembers(
                    from: response.members,
                    groupOwnerID: response.group.ownerID,
                    currentUserID: userID
                )

                await withTaskGroup(of: Void.self) { group in
                    for member in members {
                        group.addTask {
                            await ImageProvider.loadAndCacheImage(for: member.imageURL, .user)
                        }
                    }
                }

                let currentGroup = Domain.Group(
                    id: currentGroupID,
                    name: response.group.name,
                    ownerID: response.group.ownerID,
                    imageURL: response.group.imageURL,
                    createdAt: DateParser.parseISODate(response.group.createdAt),
                    members: members
                )
                GroupStorage.set(newGroup: currentGroup)
                router.navigateToGroup(currentGroup)
            } catch let error as HTTPError where error == .forbidden || error == .notFound {
                GroupStorage.currentGroup = nil
                showToast("You no longer have access to this group!")
            } catch {
                GroupStorage.currentGroup = nil
                showToast("Error: \(error)")
            }
        case .selectedNewGroup:
            withAnimation {
                groups = GroupUtils.sortedGroups(groups)
                currentGalleryItem = nil
                galleryItemsStack = []
            }
            await dispatch(.fetchGallery)
            await dispatch(.fetchRandomGalleryItems)
            await dispatch(.loadAvatars)
        case .loadAvatars:
            if let url = GroupStorage.currentGroup?.imageURL {
                groupImage = await loadImage(urlString: url)
            }
            userImage = await loadImage(urlString: user.imageURL)
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

    private func loadGroupImage() async {
        guard let currentGroup = GroupStorage.currentGroup else {
            // TODO: handle nil group
            return
        }
        let image = await ImageProvider.loadOrGetImage(
            for: currentGroup.imageURL, .group
        )
        await MainActor.run { [weak self] in
            withAnimation {
                self?.groupImage = image
            }
        }
    }

    private func loadImage(urlString: String) async -> UIImage {
        await ImageProvider.loadOrGetImage(for: urlString, .user)
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }

    private func stopPlayer() {
        isTrackPlaying = false
        audioManager.stop()
    }

    // временно
    // swiftlint:disable line_length
    private static func fetchTrack() -> Track? {
        let json = """
        {
          "id": 2026794888,
          "title": "миражи — кружок хора (>∆<)",
          "artwork_url": "https://i1.sndcdn.com/artworks-1WyHHVfSQvKviNzI-bP1zeA-large.jpg",
          "duration": 247063,
          "media": {
            "transcodings": [
              {
                "url": "https://api-v2.soundcloud.com/media/soundcloud:tracks:2026794888/cf1a0f7f-7d0e-4ce8-b601-656593f23ab3/stream/progressive",
                "preset": "mp3_1_0",
                "duration": 247066,
                "snipped": false,
                "format": {
                  "protocol": "progressive",
                  "mime_type": "audio/mpeg"
                },
                "quality": "sq",
                "is_legacy_transcoding": true
              }
            ]
          },
          "user": {
            "username": "skibidi rizz"
          }
        }
        """

        let data = Data(json.utf8)
        let track = try? JSONDecoder().decode(Track.self, from: data)
        return track
    }
    // swiftlint:enable line_length
}
// swiftline:enable type_body_length
