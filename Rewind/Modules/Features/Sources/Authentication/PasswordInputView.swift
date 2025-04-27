import SwiftUI
import UIComponents

public struct PasswordInputView: View {
    @State private var password = ""
    @State private var showNotice = false
    @State private var canResend = false
    @State private var timer: Timer? = nil
    @State private var secondsLeft = 60
    @FocusState private var isFocused: Bool
    private let flow: AuthFlow
    
    var router: AuthenticationRouter
    
    public init(flow: AuthFlow, router: AuthenticationRouter) {
        self.flow = flow
        self.router = router
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            RewindHeader {
                RewindButton(type: .leftChevron) {
                    switch flow {
                    case .registration:
                        router.dismiss(by: 2)
                    case .login:
                        router.dismiss(by: 1)
                    }
                }
            }
            
            VStack(alignment: .center, spacing: AuthConstants.fieldSpacing) {
                Text("Enter your password")
                    .modifier(RoundFontModifier(size: AuthConstants.titleFontSize))
                
                StyledTextField(
                    text: $password,
                    placeholder: "password",
                    isSecure: true
                )
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    switch flow {
                    case .registration:
                        router.navigateToName()
                    case .login:
                        router.navigateToRewind()
                    }
                }
                
                if flow == .login {
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
                .modifier(RoundFontModifier(size: 13, foregroundColor: UIComponentsAsset.lightPinkColor.swiftUIColor))
        }
    }
    
    private var notice: some View {
        VStack(spacing: 8) {
            VStack {
                Text("We’ve sent a password reset link to")
                Text(verbatim: "aleksa.khruleva@yandex.ru")
                    .foregroundStyle(UIComponentsAsset.lightPinkColor.swiftUIColor)
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
                .modifier(RoundFontModifier(size: 13, foregroundColor: UIComponentsAsset.lightPinkColor.swiftUIColor))
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
    PasswordInputView(flow: .login, router: .init(appRouter: router))
}
