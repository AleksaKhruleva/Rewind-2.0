import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class ChooseTrackPieceViewModel {
    enum Intent {
        case playTrack(startTime: Double = 0)
        case stopPlaying
    }
    
    var selectedTrack: Track
    var startedPlaying = false
    
    private let backend: SoundCloudServiceProtocol
    private let playerManager: AudioPlayerManager
    
    init(selectedTrack: Track) {
        backend = SoundCloudNetworkService()
        playerManager = AudioPlayerManager.shared
        self.selectedTrack = selectedTrack
    }
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .playTrack(startTime):
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
                
                playerManager.load(url: streamURL)
                playerManager.play(from: startTime)
                startedPlaying = true
            } catch {
                // TODO: show error
            }
            
        case .stopPlaying:
            startedPlaying = false
            playerManager.stop()
        }
    }
}
