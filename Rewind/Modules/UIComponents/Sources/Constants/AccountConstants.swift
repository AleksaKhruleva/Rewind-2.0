import Foundation

let nilAction: (() -> Void)? = nil // temporary
public enum AccountConstants {
    public static let groups = [
        ("person.2.fill", "8 group", {})
    ]
    
    public static let activities = [
        ("photo.fill.on.rectangle.fill", "124 added Rewinds", nilAction),
        ("person.fill", "3 invited people", nil),
        ("backward.fill", "245 rewind rolls", nil)
    ]
    
    public static let general = [
        ("photo.fill", "Change image", {}),
        ("pencil", "Change name", {}),
        ("key.fill", "Change password", {}),
        ("envelope.fill", "Change email", {}),
        ("gift.fill", "Set a widget", {}),
        ("questionmark.circle.fill", "Get help", {}),
        ("link.circle.fill", "Share with friends", {})
    ]
    
    public static let risky = [
        ("rectangle.portrait.and.arrow.right.fill", "Sign out", {}),
        ("trash.fill", "Delete account", {})
    ]
    
    public static let defaultFontSize: CGFloat = 17
    public static let avatarTextFontSize: CGFloat = 20
}
