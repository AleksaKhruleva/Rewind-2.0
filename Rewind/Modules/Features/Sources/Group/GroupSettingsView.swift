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
    @State private var isBlurredAvatarPresented = false
    
    public init() {}
    
    public var body: some View {
        VStack {
            header
            
            ScrollView {
                VStack(spacing: 15) {
                    avatar
                    
                    generalTable
                    
                    riskyTable
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.background)
        .overlay {
            if isBlurredAvatarPresented {
                BlurredAvatarView(
                    image: UIComponentsAsset.groupAvatar.image,
                    isPresented: $isBlurredAvatarPresented
                )
            }
        }
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
                // TODO: go back
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

#Preview {
    GroupSettingsView()
}
