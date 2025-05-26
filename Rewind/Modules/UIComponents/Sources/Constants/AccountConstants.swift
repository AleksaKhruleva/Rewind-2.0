import Foundation
import AccessibilitySupport

public let nilAction: (() -> Void)? = nil // temporary
public let nilAccessibility: RewindElement? = nil // temporary
public enum AccountConstants {
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

    public static let defaultFontSize: CGFloat = 17
    public static let avatarTextFontSize: CGFloat = 20
}
