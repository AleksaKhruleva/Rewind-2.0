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
        player?.automaticallyWaitsToMinimizeStalling = true
    }
    
    public func play(from seconds: Double, completion: @escaping (Bool) -> Void) {
        guard let player = player, let item = player.currentItem else {
            completion(false)
            return
        }
        
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else {
                completion(false)
                return
            }
            
            if item.status == .readyToPlay {
                player.play()
                completion(true)
            } else {
                self.statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                    guard let self else { return }
                    
                    if item.status == .readyToPlay {
                        player.play()
                        self.statusObserver = nil
                        completion(true)
                    } else if item.status == .failed {
                        self.statusObserver = nil
                        completion(false)
                    }
                }
            }
        }
    }
    
    public func stop() {
        player?.pause()
        statusObserver = nil
    }
    
    public func cleanup() {
        stop()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        statusObserver = nil
    }
}
