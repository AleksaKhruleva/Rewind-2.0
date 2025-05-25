import Foundation

public struct ToastState {
    var isPresented: Bool
    var title: String

    public static let empty = ToastState(
        isPresented: false,
        title: ""
    )
}
