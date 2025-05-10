import Foundation
import UIKit

public struct IdentifiableImage: Identifiable {
    public let id = UUID()
    public let image: UIImage
}
