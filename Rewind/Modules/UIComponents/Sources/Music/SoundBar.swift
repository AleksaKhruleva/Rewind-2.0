import SwiftUI

struct SoundBar: View {
    var coefficient: CGFloat
    var maxAmplitude: CGFloat = 30
    var color: Color = .pinkPrimaryLight
    
    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 5, height: maxAmplitude * coefficient)
    }
}
