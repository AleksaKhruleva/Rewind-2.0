import SwiftUI
import UIComponents

public struct PasswordInputView: View {
    @State var viewModel: PasswordInputViewModel
    @State private var showNotice = false
    @State private var canResend = false
    @State private var timer: Timer? = nil
    @State private var secondsLeft = 60
    @FocusState private var isFocused: Bool
    
    public init(flow: AuthFlow, router: AuthenticationRouter, registrationID: String?) {
        viewModel = PasswordInputViewModel(flow: flow, router: router, registrationID: registrationID)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            UIComponentsAsset.background.swiftUIColor.ignoresSafeArea()
            
            RewindHeader {
                RewindButton(type: .leftChevron) {
                    Task {
                        await viewModel.dispatch(.dismiss)
                    }
                }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter your password")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $viewModel.password,
                    placeholder: "password",
                    isSecure: true
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    Task {
                        await viewModel.dispatch(.submitPassword)
                    }
                }
                
                if viewModel.state == .loading {
                    ProgressView()
                } else if case let .error(error) = viewModel.state {
                    RewindNoteTextView(text: error.errorDescription)
                        .multilineTextAlignment(.center)
                }
                
                if case .login = viewModel.flow {
                    if showNotice {
                        notice
                            .transition(.opacity)
                    } else {
                        forgotPasswordButton
                    }
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: AuthConstants.contentTopOffsetRatio))
        }
        .onAppear {
            isFocused = true
        }
        .hideKeyboardOnTap()
        .hideKeyboardOnDrag()
    }
    
    private var forgotPasswordButton: some View {
        Button {
            showNotice = true
            startTimer()
        } label: {
            Text("Forgot password?")
                .modifier(RoundFontModifier(size: 13, foregroundColor: UIComponentsAsset.pinkPrimaryLight.swiftUIColor))
        }
    }
    
    private var notice: some View {
        VStack(spacing: 8) {
            VStack {
                Text("We’ve sent a password reset link to")
                Text(verbatim: "aleksa.khruleva@yandex.ru")
                    .foregroundStyle(UIComponentsAsset.pinkPrimaryLight.swiftUIColor)
            }
            .modifier(RoundFontModifier(size: 13))
            
            VStack {
                if canResend {
                    resendButton
                } else {
                    HStack(spacing: 0) {
                        Text("Resend in")
                        Text(String(format: "%02d", secondsLeft))
                            .frame(width: 20, alignment: .trailing)
                        Text("s")
                    }
                    .modifier(RoundFontModifier(size: 13))
                }
            }
        }
    }
    
    private var resendButton: some View {
        Button {
            // TODO: send reset link to email later
            startTimer()
        } label: {
            Text("Resend")
                .modifier(RoundFontModifier(size: 13, foregroundColor: UIComponentsAsset.pinkPrimaryLight.swiftUIColor))
        }
    }
    
    private func startTimer() {
        canResend = false
        secondsLeft = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if secondsLeft > 1 {
                secondsLeft -= 1
            } else {
                timer.invalidate()
                canResend = true
            }
        }
    }
}

#Preview {
    let router = AppRouter()
    PasswordInputView(flow: .login(), router: .init(appRouter: router), registrationID: "123")
}
