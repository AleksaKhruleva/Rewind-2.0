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
            Color.background.ignoresSafeArea()
            
            RewindHeader {
                RewindButton(type: .leftChevron) {
                    Task {
                        await viewModel.dispatch(.dismiss)
                    }
                }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text(UIComponentsStrings.Password.title)
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $viewModel.password,
                    placeholder: UIComponentsStrings.Password.placeholder,
                    isSecure: true
                )
                .rewindAccessibilityIdentifier(.auth(.input(.password)))
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
            Text(UIComponentsStrings.Password.forgot)
                .modifier(RoundFontModifier(size: 13, foregroundColor: .pinkPrimaryLight))
        }
    }
    
    private var notice: some View {
        VStack(spacing: 8) {
            VStack {
                Text(UIComponentsStrings.Password.Forgot.sent)
                Text(verbatim: "aleksa.khruleva@yandex.ru")
                    .foregroundStyle(Color.pinkPrimaryLight)
            }
            .modifier(RoundFontModifier(size: 13))
            
            VStack {
                if canResend {
                    resendButton
                } else {
                    HStack(spacing: 0) {
                        Text(UIComponentsStrings.Password.resendIn)
                        Text(String(format: "%02d", secondsLeft))
                            .frame(width: 20, alignment: .trailing)
                        Text(UIComponentsStrings.Password.ResendIn.seconds)
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
            Text(UIComponentsStrings.Password.resend)
                .modifier(RoundFontModifier(size: 13, foregroundColor: .pinkPrimaryLight))
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
