import UIKit
import AVFoundation

public final class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private let overlayButton = UIButton(type: .custom)
    private let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    
    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }
    
    var onToggle: (() -> Void)?
    
    private var isPlaying = false {
        didSet {
            updateUI()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
        setupOverlayButton()
        setupPlayIcon()
    }
    
    convenience init(player: AVPlayer) {
        self.init(frame: .zero)
        self.player = player
        self.playerLayer.player = player
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
    
    func setPlaying(_ playing: Bool) {
        guard isPlaying != playing else { return }
        isPlaying = playing
        if playing {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    private func updateUI() {
        playIcon.isHidden = isPlaying
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
