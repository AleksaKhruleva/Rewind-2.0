import SwiftUI
import UIComponents

// vremenno
let generalData = [
    ("photo.fill", "Change image", {}),
    ("pencil", "Change name", {})
]

let riskyData = [
    ("rectangle.portrait.and.arrow.right.fill", "Leave group", {}),
    ("trash.fill", "Delete group", {})
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
            RewindButton(type: .empty) {}
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
        InformationTable(title: "General", data: generalData, isRisky: false)
    }
    
    private var riskyTable: some View {
        InformationTable(title: "Risky Zone", data: riskyData, isRisky: true)
    }
}

#Preview {
    GroupSettingsView()
}
