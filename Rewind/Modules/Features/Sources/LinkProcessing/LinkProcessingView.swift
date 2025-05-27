import SwiftUI
import UIComponents
import Domain

public struct LinkProcessingView: View {
    @State private var viewModel: LinkProcessingViewModel
    @State private var hasStarted = false

    public init(url: URL, router: AppRouter, dismiss: @escaping (String) -> Void) {
        viewModel = LinkProcessingViewModel(
            url: url,
            router: router,
            dismiss: dismiss
        )
    }

    public var body: some View {
        Color.background
            .ignoresSafeArea()
            .overlay {
                VStack {
                    ProgressView()
                    Text("Adding you to the group…")
                        .modifier(RoundFontModifier(size: 15))
                        .padding(.top, 8)
                }
            }
            .onAppear {
                if !hasStarted {
                    hasStarted = true
                    Task {
                        await viewModel.addUserToGroup()
                    }
                }
            }
    }
}
