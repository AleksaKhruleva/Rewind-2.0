import SwiftUI

struct CaretView: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color.pinkColor)
            .frame(width: 2, height: 30)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}
