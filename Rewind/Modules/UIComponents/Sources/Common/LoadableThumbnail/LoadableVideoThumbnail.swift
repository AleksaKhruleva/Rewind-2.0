import Foundation
import AVFoundation
import SwiftUI

public struct LoadableVideoThumbnail<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (LoadableMediaState) -> Content
    @State private var state: LoadableMediaState = .empty

    public var body: some View {
        content(state)
            .task(id: url) {
                await loadThumbnail(url)
            }
    }

    @MainActor
    private func loadThumbnail(_ currentUrl: URL?) async {
        animateState(to: .empty)
        guard let url = currentUrl else {
            animateState(to: .failure)
            return
        }
        do {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let cgImage = try await withCheckedThrowingContinuation { cont in
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                    if let cgImage, result == .succeeded {
                        cont.resume(returning: cgImage)
                    } else if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(throwing: NSError(domain: "AsyncVideoThumbnail", code: -1))
                    }
                }
            }
            let image = Image(uiImage: UIImage(cgImage: cgImage))
            animateState(to: .ready(image))
        } catch {
            animateState(to: .failure)
        }
    }

    private func animateState(to state: LoadableMediaState) {
        withAnimation {
            self.state = state
        }
    }
}
