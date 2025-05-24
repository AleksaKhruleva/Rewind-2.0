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
    }

    enum UserGroupsState {
        case ready
        case notReady
    }

    enum CurrentGroupState {
        case ready
        case notReady
    }

    var currentGroupID: Int? {
        GroupStorage.currentGroup?.id
    }

    var showToast: (String) -> Void
    var isTrackPlaying = false
    var rolls = 0
    private(set) var groups = [Domain.Group]()
    private(set) var userGroupsState = UserGroupsState.notReady
    private(set) var currentGroupState = CurrentGroupState.ready

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

    private let router: RewindRouter
    private let backend: NetworkServiceProtocol
    private let audioManager: AudioPlayerManager
    private var mediaItems = [MediaItem]()
    private var currentIndex = 0

    init() {
        showToast = { _ in }
        backend = NetworkService()
        audioManager = AudioPlayerManager.shared

        // временно
        let items = [
            MediaItem(
                type: .imageWithMusic,
                image: UIComponentsAsset.media21.image,
                track: Self.fetchTrack()
            ),
            MediaItem(
                type: .image,
                image: UIComponentsAsset.media16.image
            )
        ]

        mediaItems = items
        currentMediaItem = items[0]
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .fetchUser:
            Task {
                do {
                    guard let tokens = Tokens() else {
                        //                        router.navigateToWelcome() // TODO: return when routing is ready
                        return
                    }
                    let response = try await backend.user(tokens: tokens)
                    user = response.toUser()
                } catch {
                    showToast("\(error.localizedDescription) 😨")
                }
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
                let responses = try await backend.fetchGroups()
                groups = sortedGroups(from: responses)
                userGroupsState = .ready
            } catch {
                groups = []
                print(error)
                // TODO: handle error
            }
        case .openGroup:
            currentGroupState = .notReady
            do {
                guard let currentGroupID,
                      let accessToken = KeychainService.shared.read(for: .accessToken),
                      let userID = jwtDecoder.getUserId(from: accessToken)
                else {
                    // TODO: throw error
                    return
                }

                let response = try await backend.fetchFullGroupDetails(id: currentGroupID)

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

        if let currentGroupID {
            if let currentGroup = groups.first(where: { $0.id == currentGroupID }) {
                groups.removeAll { $0.id == currentGroupID }
                groups.insert(currentGroup, at: 0)
            }
        }

        return groups
    }

    private func sortedMembers(from responses: [GroupMemberResponse], currentUserID: Int) -> [Member] {
        let members = responses.map { response in
            Member(
                id: response.id,
                name: response.name,
                imageData: nil,
                isOwner: response.isOwner,
                isUser: response.id == currentUserID
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
