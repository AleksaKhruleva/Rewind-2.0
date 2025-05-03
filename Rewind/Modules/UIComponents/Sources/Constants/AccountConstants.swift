import Foundation

let nilAction: (() -> Void)? = nil // temporary
public enum AccountConstants {
    public static let groups = [
        ("person.2.fill", UIComponentsStrings.Account.Groups.count(8), {})
    ]
    
    public static let activities = [
        ("photo.fill.on.rectangle.fill", UIComponentsStrings.Account.Activity.rewinds(1245), nilAction),
        ("person.fill", UIComponentsStrings.Account.Activity.people(13), nil),
        ("backward.fill", UIComponentsStrings.Account.Activity.rolls(245), nil)
    ]
    
    public static let general = [
        ("photo.fill", UIComponentsStrings.Account.General.image, {}),
        ("pencil", UIComponentsStrings.Account.General.name, {}),
        ("key.fill", UIComponentsStrings.Account.General.password, {}),
        ("envelope.fill", UIComponentsStrings.Account.General.email, {}),
        ("gift.fill", UIComponentsStrings.Account.General.widget, {}),
        ("questionmark.circle.fill", UIComponentsStrings.Account.General.help, {}),
        ("link.circle.fill", UIComponentsStrings.Account.General.share, {})
    ]
    
    public static let risky = [
        ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.Account.Risky.signout, {}),
        ("trash.fill", UIComponentsStrings.Account.Risky.delete, {})
    ]
    
    public static let defaultFontSize: CGFloat = 17
    public static let avatarTextFontSize: CGFloat = 20
}
