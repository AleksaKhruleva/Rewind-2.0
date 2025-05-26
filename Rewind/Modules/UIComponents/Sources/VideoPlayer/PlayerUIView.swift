import UIKit
import AVFoundation

let buttonSize: CGFloat = 32
let pointSize: CGFloat = 11

public final class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private let overlayButton = UIButton(type: .custom)
    private let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    private let muteButton = UIButton(type: .system)

    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
            player?.isMuted = isMuted
        }
    }

    var onToggle: (() -> Void)?
    var onMuteToggle: (() -> Void)?

    private var isPlaying = false {
        didSet {
            updateUI()
        }
    }

    private var isMuted = false {
        didSet {
            player?.isMuted = isMuted
            let config = UIImage.SymbolConfiguration(pointSize: pointSize)
            let imageName = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
            let image = UIImage(
                systemName: imageName,
                withConfiguration: config
            )
            muteButton.setImage(image, for: .normal)
            onMuteToggle?()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
        setupOverlayButton()
        setupPlayIcon()
        setupMuteButton()
    }

    convenience init(player: AVPlayer) {
        self.init(frame: .zero)
        self.player = player
        self.playerLayer.player = player
        self.player?.isMuted = isMuted
    }

    private func setupPlayerLayer() {
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        isUserInteractionEnabled = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        playerLayer.frame = bounds
        overlayButton.frame = bounds
        muteButton.frame = CGRect(
            x: bounds.maxX - buttonSize - 12,
            y: 12,
            width: buttonSize,
            height: buttonSize
        )
    }

    private func setupOverlayButton() {
        overlayButton.backgroundColor = .clear
        overlayButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        addSubview(overlayButton)
        isUserInteractionEnabled = true
    }

    private func setupPlayIcon() {
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playIcon)
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 50),
            playIcon.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupMuteButton() {
        muteButton.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: pointSize)
        let imageName = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        muteButton.setImage(image, for: .normal)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)

        muteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        muteButton.layer.cornerRadius = buttonSize / 2
        muteButton.clipsToBounds = true
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(muteButton)

        NSLayoutConstraint.activate([
            muteButton.widthAnchor.constraint(equalToConstant: buttonSize),
            muteButton.heightAnchor.constraint(equalToConstant: buttonSize),
            muteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            muteButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
        ])
    }

    @objc private func togglePlay() {
        guard let player = player else { return }

        isPlaying.toggle()

        if isPlaying {
            player.play()
        } else {
            player.pause()
        }

        onToggle?()
    }

    @objc private func toggleMute() {
        isMuted.toggle()
    }

    func setPlaying(_ playing: Bool) {
        guard isPlaying != playing else { return }
        isPlaying = playing
        if playing {
            player?.play()
        } else {
            player?.pause()
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    private func updateUI() {
        playIcon.isHidden = isPlaying
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
