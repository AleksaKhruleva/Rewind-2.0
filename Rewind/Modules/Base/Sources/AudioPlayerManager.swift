import AVFoundation

public final class AudioPlayerManager {
    public static let shared = AudioPlayerManager()
    
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    
    private init() {}
    
    public func load(url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false
    }
    
    public func play(from seconds: Double) {
        guard let player = player else { return }
        
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        
        player.seek(to: time) { [weak self] _ in
            guard let self, let item = player.currentItem else { return }
            
            if item.status == .readyToPlay {
                player.play()
            } else {
                self.statusObserver = item.observe(\.status, options: [.new]) { item, _ in
                    if item.status == .readyToPlay {
                        player.play()
                        self.statusObserver = nil
                    } else if item.status == .failed {
                        self.statusObserver = nil
                    }
                }
            }
        }
    }
    
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
    }
}
