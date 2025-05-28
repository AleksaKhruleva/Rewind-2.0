import SwiftUI
import Domain

public enum ImageProviderType {
    case group
    case user
    case media

    var placeholder: UIImage {
        switch self {
        case .group:
            return DomainAsset.groupPlaceholder.image
        case .user:
            return DomainAsset.userPlacholder.image
        case .media:
            return DomainAsset.defaultPlaceholder.image
        }
    }
}

public enum ImageProvider {
    public static func loadOrGetImage(for urlString: String?, _ type: ImageProviderType) async -> UIImage {
        guard let urlString, let url = URL(string: urlString) else {
            return type.placeholder
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
            print("Failed to load image for \(urlString): \(error)")
        }

        return type.placeholder
    }

    public static func loadAndCacheImage(for urlString: String, _ type: ImageProviderType) async {
        guard FileManagerImageStorage.shared.getImage(url: urlString) == nil,
              let url = URL(string: urlString)
        else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                FileManagerImageStorage.shared.saveImage(image: image, url: urlString)
            }
        } catch {
            print("Failed to load image for \(urlString): \(error)")
        }
    }
}
