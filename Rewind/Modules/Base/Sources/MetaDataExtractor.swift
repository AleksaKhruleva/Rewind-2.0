import SwiftUI
import PhotosUI
import ImageIO
import Domain

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
