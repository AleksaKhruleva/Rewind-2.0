import SwiftUI
import AVFoundation

public struct VideoTimelineView: View {
    @Binding var currentTime: TimeInterval
    @Binding var trimStart: TimeInterval
    @Binding var trimEnd: TimeInterval
    
    @State private var thumbnails: [UIImage] = []
    @State private var isBlurred: Bool = true
    
    private let asset: AVAsset
    private let frameCount: Int
    private let duration: TimeInterval
    private let onTrimChanged: () -> Void
    
    public init(
        currentTime: Binding<TimeInterval>,
        trimStart: Binding<TimeInterval>,
        trimEnd: Binding<TimeInterval>,
        asset: AVAsset,
        frameCount: Int,
        duration: TimeInterval,
        onTrimChanged: @escaping () -> Void
    ) {
        self._currentTime = currentTime
        self._trimStart = trimStart
        self._trimEnd = trimEnd
        self.asset = asset
        self.frameCount = frameCount
        self.duration = duration
        self.onTrimChanged = onTrimChanged
    }
    
    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let squareSize = width / CGFloat(max(frameCount, 1))
            let thumbnailSize = CGSize(width: squareSize, height: squareSize)
            
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(thumbnails.indices, id: \.self) { index in
                        Image(uiImage: thumbnails[index])
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: squareSize, height: squareSize)
                            .clipped()
                    }
                }
                .blur(radius: isBlurred ? 4 : 0)
                .animation(.easeOut(duration: 0.25), value: isBlurred)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                let trimStartX = CGFloat(trimStart / max(duration, 0.01)) * width
                let trimEndX = CGFloat(trimEnd / max(duration, 0.01)) * width
                let trimWidth = trimEndX - trimStartX
                
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.pinkPrimary, lineWidth: 2)
                    .frame(width: trimWidth, height: geo.size.height)
                    .offset(x: trimStartX)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.pinkPrimary)
                    .frame(width: 10, height: geo.size.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                onTrimChanged()
                                let delta = Double(value.translation.width / width) * duration
                                let minStart = max(0, trimEnd - 15)
                                let newStart = min(trimEnd - 1, max(minStart, trimStart + delta))
                                trimStart = newStart
                            }
                            .onEnded { _ in
                                currentTime = trimStart
                            }
                    )
                    .offset(x: trimStartX)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.pinkPrimary)
                    .frame(width: 10, height: geo.size.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                onTrimChanged()
                                let delta = Double(value.translation.width / width) * duration
                                let maxEnd = min(duration, trimStart + 15)
                                let newEnd = max(trimStart + 1, min(maxEnd, trimEnd + delta))
                                trimEnd = newEnd
                            }
                            .onEnded { _ in
                                currentTime = trimStart
                            }
                    )
                    .offset(x: trimEndX - 10)
            }
            .onAppear {
                prepareInitialPlaceholder(size: thumbnailSize)
                generateThumbnails(size: thumbnailSize)
            }
        }
    }
    
    private func prepareInitialPlaceholder(size: CGSize) {
        Task {
            do {
                let square = try await generateThumbnail(at: .zero)
                DispatchQueue.main.async {
                    self.thumbnails = Array(repeating: square, count: frameCount)
                }
            } catch {
                print("Ошибка генерации первого кадра: \(error)")
            }
        }
    }
    
    private func generateThumbnails(size: CGSize) {
        Task {
            guard let duration = try? await asset.load(.duration) else {
                isBlurred = false
                return
            }
            
            let step = CMTime(seconds: CMTimeGetSeconds(duration) / Double(frameCount), preferredTimescale: 600)
            let times: [CMTime] = (0..<frameCount).map { CMTimeMultiplyByFloat64(step, multiplier: Double($0)) }
            
            var images: [UIImage] = []
            for time in times {
                do {
                    let square = try await generateThumbnail(at: time)
                    images.append(square)
                } catch {
                    print("Ошибка генерации кадра: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                if !images.isEmpty {
                    self.thumbnails = images
                }
                self.isBlurred = false
            }
        }
    }
    
    private func generateThumbnail(at time: CMTime) async throws -> UIImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1000, height: 1000)
        
        let optionalCGImage = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage?, Error>) in
            generator.generateCGImageAsynchronously(for: time) { image, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }
        
        guard let cgImage = optionalCGImage else {
            throw NSError(domain: "CGImageNil", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить CGImage"])
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        return cropToSquare(image: uiImage)
    }
    
    private func cropToSquare(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        
        let originX = (width - side) / 2
        let originY = (height - side) / 2
        let cropRect = CGRect(x: originX, y: originY, width: side, height: side)
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
