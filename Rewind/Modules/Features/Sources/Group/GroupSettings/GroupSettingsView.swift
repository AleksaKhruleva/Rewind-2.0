import SwiftUI
import UIComponents

// vremenno
let generalData = [
    ("photo.fill", UIComponentsStrings.Group.Settings.General.name, {}),
    ("pencil", UIComponentsStrings.Group.Settings.General.image, {})
]

let riskyData = [
    ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.Group.Settings.Risky.leave, {}),
    ("trash.fill", UIComponentsStrings.Group.Settings.Risky.delete, {})
]

public struct GroupSettingsView: View {
    private let router: GroupSettingsRouter
    
    public init(router: GroupSettingsRouter) {
        self.router = router
    }
    
    public var body: some View {
        VStack {
            header
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    avatar
                    
                    generalTable
                    
                    riskyTable
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.background)
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .rightChevron).hidden()
        } centerView: {
            HeaderBadgeView(
                image: UIComponentsAsset.groupAvatar.image,
                text: "Friends"
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                router.dismiss()
            }
        }
    }
    
    private var avatar: some View {
        AvatarView(image: UIComponentsAsset.groupAvatar.image, text: "Friends")
    }
    
    private var generalTable: some View {
        InformationTable(title: UIComponentsStrings.Group.Settings.general, data: generalData, isRisky: false)
    }
    
    private var riskyTable: some View {
        InformationTable(title: UIComponentsStrings.Group.Settings.risky, data: riskyData, isRisky: true)
    }
}
