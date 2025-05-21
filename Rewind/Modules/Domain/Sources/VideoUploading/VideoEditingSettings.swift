import AVFoundation

public struct VideoEditingSettings: Hashable {
    public var startTime: CMTime
    public var endTime: CMTime
    public var isMuted: Bool
    public var composition: AVVideoComposition?

    public init(
        startTime: CMTime,
        endTime: CMTime,
        isMuted: Bool,
        composition: AVVideoComposition? = nil
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.isMuted = isMuted
        self.composition = composition
    }
}
