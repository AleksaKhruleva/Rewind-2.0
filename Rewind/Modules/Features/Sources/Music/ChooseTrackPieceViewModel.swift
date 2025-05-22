import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class ChooseTrackPieceViewModel {
    enum Intent {
        case playTrack(startTime: Double = 0)
        case stopPlaying
        case destroyPlayer
    }
    
    private(set) var selectedTrack: Track
    private(set) var isTrackPlaying: Bool = false
    
    private var currentlyLoadedURL: URL?
    private let backend: SoundCloudServiceProtocol
    private let playerManager: AudioPlayerManager
    
    init(selectedTrack: Track,) {
        self.selectedTrack = selectedTrack
        
        backend = SoundCloudNetworkService()
        playerManager = AudioPlayerManager.shared
    }
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case let .playTrack(startTime):
            isTrackPlaying = false
            playerManager.stop()
            
            Task { [weak self] in
                guard let self else { return }
                
                do {
                    let streamURL: URL
                    
                    if let existingURL = selectedTrack.streamURL {
                        streamURL = existingURL
                    } else {
                        guard let fetchedURL = try await backend.fetchStreamURL(for: selectedTrack) else {
                            return
                        }
                        selectedTrack.streamURL = fetchedURL
                        streamURL = fetchedURL
                    }
                    
                    if currentlyLoadedURL != streamURL {
                        playerManager.stop()
                        playerManager.load(url: streamURL)
                        currentlyLoadedURL = streamURL
                    }
                    
                    playerManager.play(from: startTime) { [weak self] success in
                        self?.isTrackPlaying = success
                    }
                    
                } catch {
                    // TODO: show error
                }
            }
            
        case .stopPlaying:
            isTrackPlaying = false
            playerManager.stop()
            currentlyLoadedURL = nil
            
        case .destroyPlayer:
            isTrackPlaying = false
            playerManager.cleanup()
            currentlyLoadedURL = nil
        }
    }
}
