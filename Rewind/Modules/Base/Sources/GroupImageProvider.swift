import SwiftUI
import Domain

public enum GroupImageProvider {
    public static func loadOrGetImage(for urlString: String?) async -> UIImage {
        guard let urlString, let url = URL(string: urlString) else {
            return DomainAsset.groupPlaceholder.image
        }

        if let cached = FileManagerImageStorage.shared.getImage(url: urlString) {
            return cached
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                FileManagerImageStorage.shared.saveImage(image: image, url: urlString)
                return image
            }
        } catch {
            print("Failed to load group image for \(urlString): \(error)")
        }

        return DomainAsset.groupPlaceholder.image
    }

    public static func loadAndCacheImage(for urlString: String) async {
        guard FileManagerImageStorage.shared.getImage(url: urlString) == nil,
              let url = URL(string: urlString)
        else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                FileManagerImageStorage.shared.saveImage(image: image, url: urlString)
            }
        } catch {
            print("Failed to load group image for \(urlString): \(error)")
        }
    }
}
