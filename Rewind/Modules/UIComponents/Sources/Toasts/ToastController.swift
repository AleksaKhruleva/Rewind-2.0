import SwiftUI

@MainActor @Observable
public final class ToastController {
    private(set) var state: ToastState
    private var hideTask: Task<Void, Error>?
    private var animatedState: ToastState {
        get { state }
        set { withAnimation(.spring) { state = newValue } }
    }

    public init(
        state: ToastState = ToastState.empty,
        hideSnackbarTask: Task<Void, Error>? = nil
    ) {
        self.state = state
        self.hideTask = hideTask
    }

    public func present(with title: String) {
        if state.isPresented {
            state.title = title
            hideTask?.cancel()
        } else {
            animatedState = ToastState(
                isPresented: true,
                title: title
            )
        }

        hideTask = Task {
            try await Task.sleep(nanoseconds: 3_500_000_000)
            try Task.checkCancellation()

            animatedState = .empty
        }
    }

    func hide() {
        hideTask?.cancel()
        animatedState = .empty
    }
}
