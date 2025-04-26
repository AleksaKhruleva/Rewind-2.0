import SwiftUI

extension View {
    public func disabledWithOpacity(_ trueFlag: Bool) -> some View {
        self
            .disabled(trueFlag)
            .opacity(trueFlag ? 0.5 : 1)
    }
}

