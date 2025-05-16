import SwiftUI
import Combine
import AVFoundation
import Networking
import Domain

@MainActor
final class FindTrackViewModel: ObservableObject {
    enum Intent {
        case loadTracks
        case togglePlayback(track: Track)
        case loadMoreTracks(currentTrack: Track)
    }
    
    @Published var searchText = ""
    
    @Published private(set) var tracks = [Track]()
    @Published private(set) var currentlyPlayingTrackID: Int?
    @Published private(set) var currentlyLoadingTrackID: Int?
    
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasReachedEnd = false
    
    private var isShowingDefaultTracks = true
    
    private var defaultTracks = [Track]()
    private var defaultNextHref: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var player: AVPlayer? = nil
    private var endObserver: NSObjectProtocol?
    private var nextHref: String?
    
    private let backend: SoundCloudServiceProtocol
    
    init() {
        self.backend = SoundCloudNetworkService()
        setupSearchTextDebounce()
    }
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case .loadTracks:
            loadDefaultTracks()
        case .togglePlayback(track: let track):
            toggleTrackPlayback(track)
        case .loadMoreTracks(currentTrack: let currentTrack):
            loadMoreTracksIfNeeded(currentTrack: currentTrack)
        }
    }
    
    private func setupSearchTextDebounce() {
        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .removeDuplicates()
            .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                Task {
                    await self.search(for: text)
                }
            }
            .store(in: &cancellables)
    }
    
    private func search(for query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            tracks = defaultTracks
            nextHref = defaultNextHref
            hasReachedEnd = (defaultNextHref == nil)
            isShowingDefaultTracks = true
            return
        }
        
        do {
            let response = try await backend.searchTracks(query: trimmedQuery, limit: 30)
            self.tracks = response.collection
            self.nextHref = response.next_href
            self.hasReachedEnd = (response.next_href == nil)
            self.isShowingDefaultTracks = false
        } catch {
            tracks = defaultTracks
            nextHref = defaultNextHref
            hasReachedEnd = (defaultNextHref == nil)
            isShowingDefaultTracks = true
            print(error)
            // TODO: show error
        }
    }
    
    private func loadDefaultTracks() {
        Task {
            do {
                let response = try await backend.fetchCharts(limit: 30)
                defaultTracks = response.collection
                defaultNextHref = response.next_href
                isShowingDefaultTracks = true
                
                tracks = defaultTracks
                nextHref = defaultNextHref
                hasReachedEnd = (defaultNextHref == nil)
            } catch {
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    print("Сервер не ответил вовремя. Попробуйте ещё раз.")
                } else {
                    print("Произошла ошибка при загрузке треков.")
                }
                
                print("Ошибка загрузки чартов: \(error)")
            }
        }
    }
    
    private func loadMoreTracksIfNeeded(currentTrack: Track) {
        guard !isLoadingMore,
              !hasReachedEnd,
              currentTrack.id == tracks.last?.id
        else { return }
        
        guard let hrefToUse = nextHref else { return }
        
        isLoadingMore = true
        
        Task {
            defer { isLoadingMore = false }
            
            do {
                let response = try await backend.fetchNextPage(
                    from: hrefToUse,
                    for: isShowingDefaultTracks ? .charts : .search
                )
                
                if isShowingDefaultTracks {
                    defaultTracks.append(contentsOf: response.collection)
                    tracks = defaultTracks
                } else {
                    tracks.append(contentsOf: response.collection)
                }
                
                self.nextHref = response.next_href
                self.hasReachedEnd = (response.next_href == nil)
                
                if isShowingDefaultTracks {
                    self.defaultNextHref = response.next_href
                }
            } catch {
                print(error)
                // TODO: handle error
            }
        }
    }
    
    private func toggleTrackPlayback(_ track: Track) {
        if currentlyPlayingTrackID == track.id {
            player?.pause()
            currentlyPlayingTrackID = nil
            return
        }
        
        currentlyLoadingTrackID = track.id
        
        Task {
            defer { currentlyLoadingTrackID = nil }
            
            do {
                let streamURL: URL
                
                if let cachedURL = track.streamURL {
                    streamURL = cachedURL
                } else {
                    guard let fetchedURL = try await backend.fetchStreamURL(for: track) else {
                        return
                    }
                    streamURL = fetchedURL
                    
                    if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                        tracks[index].streamURL = fetchedURL
                    }
                }
                
                let playerItem = AVPlayerItem(url: streamURL)
                
                await MainActor.run {
                    if let endObserver {
                        NotificationCenter.default.removeObserver(endObserver)
                    }
                    
                    endObserver = NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { [weak self] _ in
                        Task { @MainActor in
                            self?.currentlyPlayingTrackID = nil
                        }
                    }
                    
                    if player == nil {
                        player = AVPlayer()
                    }
                    
                    player?.replaceCurrentItem(with: playerItem)
                    player?.playImmediately(atRate: 1.0)
                    currentlyPlayingTrackID = track.id
                }
            } catch {
                await MainActor.run {
                    currentlyPlayingTrackID = nil
                }
            }
        }
    }
}
