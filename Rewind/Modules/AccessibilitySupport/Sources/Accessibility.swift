import Foundation
import SwiftUI

extension View {
    public func rewindAccessibilityIdentifier(_ identifier: RewindElement) -> some View {
        self.accessibilityIdentifier(identifier.accessibilityID)
    }
}
