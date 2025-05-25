import Foundation
import AccessibilitySupport

public let nilAction: (() -> Void)? = nil // temporary
public let nilAccessibility: RewindElement? = nil // temporary
public enum AccountConstants {
    public static let groups = [
        ("person.2.fill", UIComponentsStrings.Account.Groups.count(8), nilAccessibility, {})
    ]

    public static let activities = [
        (
            "photo.fill.on.rectangle.fill",
            UIComponentsStrings.Account.Activity.rewinds(1245),
            nilAccessibility,
            nilAction
        ),
        ("person.fill", UIComponentsStrings.Account.Activity.people(13), nilAccessibility, nil),
        ("backward.fill", UIComponentsStrings.Account.Activity.rolls(245), nilAccessibility, nil)
    ]

    public static let risky = [
        ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.Account.Risky.signout, nilAccessibility, {}),
        ("trash.fill", UIComponentsStrings.Account.Risky.delete, nilAccessibility, {})
    ]

    public static let defaultFontSize: CGFloat = 17
    public static let avatarTextFontSize: CGFloat = 20
}
