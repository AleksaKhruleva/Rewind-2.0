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
        enum RandomGalleryItemsFetchType {
            case hard
            case soft
        }

        case fetchUser
        case toggleTrackPlaying
        case stopPlayer
        case showNextMediaItem
        case fetchGroups
        case openGroup
        case selectedNewGroup(Domain.Group)
        case loadAvatars

        case fetchGallery
        case fetchRandomGalleryItems(RandomGalleryItemsFetchType)

        case likeMedia
        case unlikeMedia
        case fetchCurrentMedia
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
    var isVideoPlaying = true
    var rolls = 0
    var groupImage: UIImage?
    var groupGallery = [GalleryItem]()
    var userImage: UIImage?
    private(set) var groups = [Domain.Group]()
    private(set) var userGroupsState = UserGroupsState.notReady
    private(set) var currentGroupState = CurrentGroupState.ready
    var currentFilters = FilterSettings()

    var currentGalleryItem: GalleryItem?
    let router: RewindRouter

    var fetchedUser: User?
    var user: User {
        get {
            guard let fetchedUser else {
                //                router.navigateToWelcome() // TODO: return when routing is ready
                return User(
                    name: "",
                    email: "",
                    imageURL: "",
                    invitedMembers: 0,
                    memoriesAdded: 0,
                    memoriesViewed: 0,
                    createdAt: ""
                )
            }
            return fetchedUser
        }
        set {
            fetchedUser = newValue
        }
    }

    private let backend: NetworkServiceProtocol
    private let soundCloudBackend: SoundCloudNetworkService
    private let jwtDecoder: JWTDecoder
    private let audioManager: AudioPlayerManager
    private var galleryItemsStack = [GalleryItem]()

    init(router: RewindRouter) {
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
        soundCloudBackend = SoundCloudNetworkService()
        jwtDecoder = JWTDecoder()
        audioManager = AudioPlayerManager.shared
    }

    func dispatch(_ intent: Intent) async {
        switch intent {
        case .fetchUser:
            stopPlayer()
            do {
                guard let tokens = Tokens() else {
                    // router.navigateToWelcome() // TODO: return when routing is ready
                    return
                }
                let response = try await backend.user(tokens: tokens, userId: nil)
                user = response.toUser()
            } catch {
                showToast("\(error.localizedDescription) 😨")
            }
        case .fetchCurrentMedia:
            isVideoPlaying = false
            stopPlayer()
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let memoryId = currentGalleryItem?.id {
                    currentGalleryItem = try await backend.getMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: memoryId
                    ).toGalleryItem()
                    if let trackInfo = currentGalleryItem?.memory.trackInfo {
                        do {
                            let response = try await soundCloudBackend.fetchTrack(by: trackInfo.id)
                            var lightTrack = response.toLightTrack(with: trackInfo)

                            if let streamURL = try await soundCloudBackend.fetchStreamURL(for: lightTrack) {
                                lightTrack.streamURL = streamURL
                            } else {
                                showToast("Couldn't get track stream URL.")
                            }
                            currentGalleryItem?.memory.lightTrack = lightTrack
                        } catch {
                            showToast("Couldn't download music :( Try again later!")
                        }
                    }
                }
            } catch {
                await dispatch(.showNextMediaItem)
            }
        case .fetchGallery:
            stopPlayer()
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
        case let .fetchRandomGalleryItems(type):
            isVideoPlaying = false
            stopPlayer()
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.getRandomMedias(
                        tokens: tokens,
                        groupId: groupId,
                        mediaType: currentFilters.mediaTypes,
                        favourites: currentFilters.favourites,
                        startTime: currentFilters.startDate?.toISO8601String(),
                        endTime: currentFilters.endDate?.toISO8601String(),
                        tags: currentFilters.tags,
                        limit: 10
                    )
                    if response.memories?.isEmpty ?? true {
                        withAnimation {
                            currentGalleryItem = nil
                            galleryItemsStack = []
                        }
                        return
                    }
                    let proceededGalleryItems = response.memories?.map { $0.toGalleryItem() }.shuffled() ?? []
                    withAnimation(.easeInOut(duration: 0.1)) {
                        if type == .soft {
                            galleryItemsStack.append(contentsOf: proceededGalleryItems)
                            if currentGalleryItem == nil {
                                currentGalleryItem = galleryItemsStack.first
                            }
                        } else {
                            galleryItemsStack = proceededGalleryItems
                            currentGalleryItem = galleryItemsStack.first
                        }
                        Task {
                            if let trackInfo = currentGalleryItem?.memory.trackInfo {
                                do {
                                    let response = try await soundCloudBackend.fetchTrack(by: trackInfo.id)
                                    var lightTrack = response.toLightTrack(with: trackInfo)

                                    if let streamURL = try await soundCloudBackend.fetchStreamURL(for: lightTrack) {
                                        lightTrack.streamURL = streamURL
                                    } else {
                                        showToast("Couldn't get track stream URL.")
                                    }
                                    currentGalleryItem?.memory.lightTrack = lightTrack
                                } catch {
                                    showToast("Couldn't download music :( Try again later!")
                                }
                            }
                        }
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .toggleTrackPlaying:
            if let currentGalleryItem, !isTrackPlaying, let lightTrack = currentGalleryItem.memory.lightTrack {
                guard let streamURL = lightTrack.streamURL else {
                    return
                }
                audioManager.load(url: streamURL)
                audioManager.play(
                    from: lightTrack.startTime,
                    duration: lightTrack.duration,
                    loop: true
                ) { [weak self] isPlaying in
                    self?.isTrackPlaying = isPlaying
                }
            } else {
                stopPlayer()
            }
        case .showNextMediaItem:
            if galleryItemsStack.count > 1 {
                stopPlayer()
                rolls += 1
                do {
                    if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                        let response = try await backend.viewMemories(
                            tokens: tokens,
                            groupId: groupId,
                            count: 1
                        )
                        guard response.success else { return }
                        if var galleryItem = galleryItemsStack.popLast() {
                            if let trackInfo = galleryItem.memory.trackInfo {
                                do {
                                    let response = try await soundCloudBackend.fetchTrack(by: trackInfo.id)
                                    var lightTrack = response.toLightTrack(with: trackInfo)
                                    
                                    if let streamURL = try await soundCloudBackend.fetchStreamURL(for: lightTrack) {
                                        lightTrack.streamURL = streamURL
                                    } else {
                                        showToast("Couldn't get track stream URL.")
                                    }
                                    galleryItem.memory.lightTrack = lightTrack
                                } catch {
                                    showToast("Couldn't download music :( Try again later!")
                                }
                            }
                            currentGalleryItem = galleryItem
                        }
                    }
                } catch {
                    showToast(UIComponentsStrings.Toast.error)
                }
            }
            if galleryItemsStack.count == 0 {
                await dispatch(.fetchRandomGalleryItems(.soft))
            }
        case .fetchGroups:
            stopPlayer()
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
            isVideoPlaying = false
            stopPlayer()
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
            isVideoPlaying = false
            stopPlayer()
            withAnimation {
                groups = GroupUtils.sortedGroups(groups)
                currentGalleryItem = nil
                galleryItemsStack = []
            }
            await dispatch(.fetchGallery)
            await dispatch(.fetchRandomGalleryItems(.soft))
            await dispatch(.loadAvatars)
        case .loadAvatars:
            if let url = GroupStorage.currentGroup?.imageURL {
                groupImage = await loadImage(urlString: url)
            }
            userImage = await loadImage(urlString: user.imageURL)
        case .likeMedia:
            do {
                if let tokens = Tokens(),
                   let groupId = GroupStorage.currentGroup?.id,
                   let galleryItemId = currentGalleryItem?.id {
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
                   let galleryItemId = currentGalleryItem?.id {
                    _ = try await backend.unlikeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItemId
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .stopPlayer:
            stopPlayer()
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
}
// swiftline:enable type_body_length
