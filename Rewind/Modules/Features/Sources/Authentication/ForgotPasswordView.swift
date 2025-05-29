import SwiftUI
import UIComponents

public struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    @State private var error: String?
    @Environment(\.showToast) private var showToast

    public init(url: URL, router: AppRouter) {
        viewModel = ForgotPasswordViewModel(url: url, router: router)
    }

    public var body: some View {
        GenericInputSheetView(
            item: .password,
            title: "Enter new passworf",
            error: $error
        ) { newPassword in
            Task {
                await viewModel.dispatch(.resetPassword(newPassword))
            }
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.background

                    ProgressView(viewModel.message)
                        .modifier(RoundFontModifier(size: 15))
                }
            }
        }
        .onChange(of: error) { _, newValue in
            if let newValue, !newValue.isEmpty {
                showToast(newValue)
            }
        }
        .onChange(of: viewModel.toastMessage) { _, newValue in
            if let newValue, !newValue.isEmpty {
                showToast(newValue)
            }
        }
    }
}
