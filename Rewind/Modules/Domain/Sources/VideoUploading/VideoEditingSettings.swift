import AVFoundation

public struct VideoEditingSettings: Hashable {
    public var startTime: CMTime
    public var endTime: CMTime
    public var isMuted: Bool
    public var composition: AVVideoComposition?
    public var cropScale: CGFloat
    public var cropOffset: CGSize
    
    public init(
        startTime: CMTime,
        endTime: CMTime,
        isMuted: Bool,
        composition: AVVideoComposition? = nil,
        cropScale: CGFloat,
        cropOffset: CGSize
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.isMuted = isMuted
        self.composition = composition
        self.cropScale = cropScale
        self.cropOffset = cropOffset
    }
}
