import AVFoundation

public final class AudioPlayerManager {
    public static let shared = AudioPlayerManager()

    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private var playbackObserver: Any?
    private var playbackEndTime: CMTime?
    private var timeControlObserver: NSKeyValueObservation?

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

    // MARK: - Universal Play

    public func play(
        from startSeconds: Double,
        duration: Double? = nil,
        loop: Bool = false,
        completion: @escaping (Bool) -> Void
    ) {
        guard let player = player, let item = player.currentItem else {
            completion(false)
            return
        }

        let assetDuration = item.duration.seconds
        let clampedStart = min(startSeconds, assetDuration)

        let startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
        let endTime: CMTime? = {
            guard let duration else { return nil }
            let maxEnd = min(clampedStart + duration, assetDuration)
            return CMTime(seconds: maxEnd, preferredTimescale: 600)
        }()

        playbackEndTime = endTime

        timeControlObserver?.invalidate()
        timeControlObserver = nil
        statusObserver?.invalidate()
        statusObserver = nil

        if let observer = playbackObserver {
            player.removeTimeObserver(observer)
            playbackObserver = nil
        }

        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else {
                completion(false)
                return
            }

            self.timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                guard let self else { return }

                if player.timeControlStatus == .playing {
                    self.timeControlObserver?.invalidate()
                    self.timeControlObserver = nil
                    completion(true)
                }
            }

            let playBlock = {
                if loop, let endTime {
                    self.startLoopingPlayback(startTime: startTime, endTime: endTime)
                } else if let endTime {
                    self.startOneTimePlaybackSegment(startTime: startTime, endTime: endTime)
                } else {
                    player.play()
                }
            }

            if item.status == .readyToPlay {
                playBlock()
            } else {
                self.statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                    guard let self else { return }

                    if item.status == .readyToPlay {
                        self.statusObserver?.invalidate()
                        self.statusObserver = nil
                        playBlock()
                    } else if item.status == .failed {
                        self.statusObserver?.invalidate()
                        self.statusObserver = nil
                        self.timeControlObserver?.invalidate()
                        self.timeControlObserver = nil
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

    private func startOneTimePlaybackSegment(startTime: CMTime, endTime: CMTime) {
        guard let player else { return }

        player.play()

        playbackObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] currentTime in
            guard let self else { return }

            if currentTime >= endTime {
                self.stop()
            }
        }
    }

    // MARK: - Stop / Cleanup

    public func stop() {
        player?.pause()
        statusObserver = nil
        timeControlObserver = nil

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
        timeControlObserver = nil
        playbackEndTime = nil
    }
}
