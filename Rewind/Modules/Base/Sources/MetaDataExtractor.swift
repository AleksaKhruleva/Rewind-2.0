import SwiftUI
import PhotosUI
import ImageIO
import Domain
import AVFoundation

public final class MetaDataExtractor {
    public static let shared = MetaDataExtractor()

    private init() {}

    public func extractCoordinates(from item: PhotosPickerItem) async -> MediaCoordinates? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        else {
            return nil
        }

        let latitude = (latRef == "S" ? -lat : lat)
        let longitude = (lonRef == "W" ? -lon : lon)
        return MediaCoordinates(latitude: latitude, longitude: longitude)
    }

    public func extractOriginalDateString(from item: PhotosPickerItem) async -> String? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String
        else {
            return nil
        }
        return dateString
    }
}

public extension MetaDataExtractor {
    func extractCoordinates(from asset: AVAsset) async -> MediaCoordinates? {
        do {
            let allMetadata = try await asset.load(.metadata)

            for item in allMetadata {
                if let key = item.commonKey?.rawValue, key == "location" {
                    if let location = try? await item.load(.stringValue) {
                        return parseLocationString(location)
                    }
                }
            }

            let formats = try await asset.load(.availableMetadataFormats)
            for format in formats {
                let metadata = try await asset.loadMetadata(for: format)
                for item in metadata {
                    if let key = item.commonKey?.rawValue, key == "location" {
                        if let location = try? await item.load(.stringValue) {
                            return parseLocationString(location)
                        }
                    }
                }
            }
        } catch {
            print("Failed to extract video location metadata: \(error)")
        }

        return nil
    }

    func extractOriginalDateString(from asset: AVAsset) async -> String? {
        do {
            let allMetadata = try await asset.load(.metadata)

            for item in allMetadata {
                if let key = item.commonKey?.rawValue, key == "creationDate" {
                    return try await item.load(.stringValue)
                }
            }
        } catch {
            print("Failed to extract creation date: \(error)")
        }

        return nil
    }

    private func parseLocationString(_ location: String) -> MediaCoordinates? {
        let regex = #"\+([0-9.]+)([\+-])([0-9.]+)"#
        guard let match = location.range(of: regex, options: .regularExpression) else {
            return nil
        }

        let matchedString = String(location[match])
        let components = matchedString
            .replacingOccurrences(of: "+", with: " +")
            .replacingOccurrences(of: "-", with: " -")
            .split(separator: " ")
            .compactMap { Double($0) }

        guard components.count == 2 else { return nil }
        return MediaCoordinates(latitude: components[0], longitude: components[1])
    }
}
