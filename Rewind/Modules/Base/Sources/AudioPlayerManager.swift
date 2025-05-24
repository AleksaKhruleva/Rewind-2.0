import AVFoundation

public final class AudioPlayerManager {
    public static let shared = AudioPlayerManager()
    
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private var playbackObserver: Any?
    private var playbackEndTime: CMTime?
    
    private init() {}
    
    // MARK: - Load
    
    public func load(url: URL) {
        if let currentURLAsset = playerItem?.asset as? AVURLAsset,
           currentURLAsset.url == url {
            print("same URL")
            return
        }
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
    }
    
    // MARK: - Play (single start)
    
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
    
    // MARK: - Play (looping fragment)
    
    public func play(from startSeconds: Double, duration: Double, completion: @escaping (Bool) -> Void) {
        guard let player = player, let item = player.currentItem else {
            completion(false)
            return
        }
        
        let startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        let endTime = CMTime(seconds: startSeconds + duration, preferredTimescale: 600)
        
        self.playbackEndTime = endTime
        
        if let observer = playbackObserver {
            player.removeTimeObserver(observer)
            playbackObserver = nil
        }
        
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else {
                completion(false)
                return
            }
            
            if item.status == .readyToPlay {
                self.startLoopingPlayback(startTime: startTime, endTime: endTime)
                completion(true)
            } else {
                self.statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                    guard let self else { return }
                    
                    if item.status == .readyToPlay {
                        self.startLoopingPlayback(startTime: startTime, endTime: endTime)
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
    
    private func startLoopingPlayback(startTime: CMTime, endTime: CMTime) {
        guard let player else { return }
        
        player.play()
        
        playbackObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] currentTime in
            guard self != nil else { return }
            
            if currentTime >= endTime {
                player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                player.play()
            }
        }
    }
    
    // MARK: - Stop / Cleanup
    
    public func stop() {
        player?.pause()
        statusObserver = nil
        
        if let observer = playbackObserver {
            player?.removeTimeObserver(observer)
            playbackObserver = nil
        }
    }
    
    public func cleanup() {
        stop()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        statusObserver = nil
        playbackEndTime = nil
    }
}
