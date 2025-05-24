// swiftlint:disable duplicate_imports
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
// swiftlint:enable duplicate_imports

public struct QRCodeGenerator {
    public init() {}

    public static func generate(
        from string: String,
        size: CGFloat = 512,
        pixelColor: Color,
        backgroundColor: UIColor = .clear,
        colorScheme: ColorScheme
    ) -> UIImage? {
        let context = CIContext()
        let qrFilter = CIFilter.qrCodeGenerator()
        let colorFilter = CIFilter.falseColor()

        qrFilter.setValue(Data(string.utf8), forKey: "inputMessage")
        guard var qrImage = qrFilter.outputImage else { return nil }
        qrImage = qrImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        let resolvedUIColor: UIColor = {
            switch colorScheme {
            case .dark:
                return UIColor(pixelColor).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            case .light:
                return UIColor(pixelColor).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            @unknown default:
                return UIColor(pixelColor)
            }
        }()

        colorFilter.inputImage = qrImage
        colorFilter.color0 = CIColor(color: resolvedUIColor)
        colorFilter.color1 = CIColor(color: backgroundColor)

        guard let output = colorFilter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent)
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
