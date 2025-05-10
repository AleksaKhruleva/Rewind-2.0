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
    }
    
    @Published var searchText = ""
    @Published private(set) var tracks = [Track]()
    @Published private(set) var currentlyPlayingTrackID: Int?
    @Published private(set) var currentlyLoadingTrackID: Int?
    
    private var defaultTracks = [Track]()
    private var cancellables = Set<AnyCancellable>()
    private var player: AVPlayer? = nil
    private var endObserver: NSObjectProtocol?
    private let backend: SoundCloudServiceProtocol
    
    init() {
        self.backend = SoundCloudNetworkService()
        setupSearchTextDebounce()
    }
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case .loadTracks:
            loadDefaultTracks()
        case let .togglePlayback(track):
            toggleTrackPlayback(track)
        }
    }
    
    private func loadDefaultTracks() {
        Task {
            do {
                defaultTracks = try await backend.fetchCharts(limit: 30)
                tracks = defaultTracks
            } catch {
                // TODO: show error
            }
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
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tracks = defaultTracks
            return
        }
        
        tracks = []
        
        do {
            tracks = try await backend.searchTracks(query: query)
        } catch {
            print("ABOBA")
            // TODO: show error
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
                if let streamURL = try await backend.fetchStreamURL(for: track) {
                    player?.pause()
                    
                    let playerItem = AVPlayerItem(url: streamURL)
                    
                    if let endObserver {
                        NotificationCenter.default.removeObserver(endObserver)
                    }
                    
                    endObserver = NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { [weak self] _ in
                        guard let self else { return }
                        Task { @MainActor in
                            self.currentlyPlayingTrackID = nil
                        }
                    }
                    
                    player = AVPlayer(playerItem: playerItem)
                    player?.play()
                    currentlyPlayingTrackID = track.id
                } else {
                    // TODO: show error
                }
            } catch {
                // TODO: show error
            }
        }
    }
}
