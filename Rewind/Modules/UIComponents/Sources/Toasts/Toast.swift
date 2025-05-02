import SwiftUI

public struct ToastView: View {
    @State
    private var controller: ToastController
    private var title: String
    
    public init(controller: ToastController) {
        self.controller = controller
        title = controller.state.title
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if controller.state.isPresented {
                content
                    .padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity)
                    )
                    .onTapGesture {
                        controller.hide()
                    }
            }
        }
    }
    
    private var content: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .modifier(RoundFontModifier(size: 14, weight: .black, foregroundColor: .textPrimaryInverted))
                .padding(.vertical)
            
            Spacer()
        }
        .padding(.leading)
        .padding(.trailing)
        .background(Color.backgroundInverted)
        .cornerRadius(16)
    }
}

#Preview {
    ToastView(
        controller: .init(
            state: .init(
                isPresented: true,
                title: "Пост сохранен в избранное"
            )
        )
    )
}
