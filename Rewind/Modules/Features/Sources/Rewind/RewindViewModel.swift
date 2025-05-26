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
    private(set) var groups = [Domain.Group]()
    private(set) var userGroupsState = UserGroupsState.notReady
    private(set) var currentGroupState = CurrentGroupState.ready
    private(set) var currentMediaItem: MediaItem
    let router: RewindRouter

    var fetchedUser: User?
    var user: User {
        get {
            guard let fetchedUser else {
                //                router.navigateToWelcome() // TODO: return when routing is ready
                return User(name: "", email: "")
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
    private var mediaItems = [MediaItem]()
    private var currentIndex = 0

    init(router: RewindRouter) {
        self.router = router
        showToast = { _ in }
        backend = NetworkService()
        jwtDecoder = JWTDecoder()
        audioManager = AudioPlayerManager.shared

        let items = MediaItem.stubs(track: Self.fetchTrack())

        mediaItems = items
        currentMediaItem = items[0]
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
        case .toggleTrackPlaying:
            if !isTrackPlaying {
                guard let streamURL = currentMediaItem.track?.streamURL else {
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
            withAnimation {
                rolls += 1
                currentIndex = (currentIndex + 1) % mediaItems.count
                currentMediaItem = mediaItems[currentIndex]
            }
        case .fetchGroups:
            userGroupsState = .notReady
            do {
                guard let tokens = Tokens() else { return }
                let responses = try await backend.fetchGroups(tokens: tokens)
                groups = sortedGroups(from: responses)
                if let currentGroupId = GroupStorage.currentGroup?.id {
                    if let updatedGroup = groups.first(where: { $0.id == currentGroupId }) {
                        GroupStorage.set(newGroup: updatedGroup)
                    } else {
                        GroupStorage.currentGroup = nil
                        print("Current group is no longer available")
                    }
                }
                userGroupsState = .ready
            } catch {
                groups = []
                print(error)
                // TODO: handle error
            }
        case .openGroup:
            currentGroupState = .notReady
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

                let members = sortedMembers(
                    from: response.members,
                    currentUserID: userID
                )

                let currentGroup = Domain.Group(
                    id: currentGroupID,
                    name: response.group.name,
                    ownerID: response.group.ownerID,
                    members: members,
                    createdAt: DateParser.parseISODate(response.group.createdAt)
                )

                currentGroupState = .ready
                router.navigateToGroup(currentGroup)
            } catch {
                print(error)
                // TODO: handle error
            }
        case let .selectedNewGroup(newGroup):
            groups = sortedGroups(
                groups,
                currentGroupID: GroupStorage.currentGroup?.id
            )
            print(newGroup.name)
        }
    }

    private func sortedGroups(from responses: [GroupResponse]) -> [Domain.Group] {
        var groups = responses
            .map { response in
                Group(
                    id: response.groupID,
                    name: response.name
                    // imageData: ...
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let currentGroupID = GroupStorage.currentGroup?.id {
            if let currentGroup = groups.first(where: { $0.id == currentGroupID }) {
                groups.removeAll { $0.id == currentGroupID }
                groups.insert(currentGroup, at: 0)
            }
        }

        return groups
    }

    private func sortedGroups(_ groups: [Domain.Group], currentGroupID: Int?) -> [Domain.Group] {
        var sorted = groups.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let currentGroupID,
           let currentGroup = sorted.first(where: { $0.id == currentGroupID }) {
            sorted.removeAll { $0.id == currentGroupID }
            sorted.insert(currentGroup, at: 0)
        }

        return sorted
    }

    private func sortedMembers(from responses: [GroupMemberResponse], currentUserID: String) -> [Member] {
        let members = responses.map { response in
            Member(
                id: String(response.id),
                name: response.name,
                imageData: nil,
                isOwner: response.isOwner,
                isUser: String(response.id) == currentUserID
            )
        }

        return members.sorted { lhs, rhs in
            switch (lhs.isOwner, rhs.isOwner) {
            case (true, false): return true
            case (false, true): return false
            default:
                switch (lhs.isUser, rhs.isUser) {
                case (true, false): return true
                case (false, true): return false
                default:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
        }
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
