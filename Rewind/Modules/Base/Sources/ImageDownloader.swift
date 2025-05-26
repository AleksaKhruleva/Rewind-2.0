import SwiftUI
import Foundation
import Domain

public final class ImageDownloader {
    public static let shared = ImageDownloader()

    enum ImageDownloaderError: Error {
        case invalidUrl
        case invalidImage
        case network(Error)
        case badStatusCode(Int)
    }

    // Temporary
    public func template() async -> UIImage {
        do {
            return try await downloadImage(from: "https://img-s-msn-com.akamaized.net/tenant/amp/entityid/AA1gATN9.img")
        } catch {
            return DomainAsset.userPlacholder.image
        }
    }

    public func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ImageDownloaderError.invalidUrl
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw ImageDownloaderError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ImageDownloaderError.badStatusCode(code)
        }

        guard let image = UIImage(data: data) else {
            throw ImageDownloaderError.invalidImage
        }
        return image
    }
}
