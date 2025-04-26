import SwiftUI
import UIComponents

let images = [
    UIComponentsAsset.media1.image,
    UIComponentsAsset.media2.image,
    UIComponentsAsset.media3.image,
    UIComponentsAsset.media4.image,
    UIComponentsAsset.media6.image,
    UIComponentsAsset.media7.image,
    UIComponentsAsset.media8.image,
    UIComponentsAsset.media9.image,
    UIComponentsAsset.media10.image,
]

public struct GroupView: View {
    @State private var isBlurredAvatarPresented = false
    
    public init() {}
    
    public var body: some View {
        VStack {
            header
            
            ScrollView {
                VStack(spacing: 15) {
                    avatar
                        .onTapGesture {
                            withAnimation {
                                isBlurredAvatarPresented.toggle()
                            }
                        }
                    
                    membersTable
                    
                    activityTable
                    
                    galleryPreview
                    
                    groupExistenceNote
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
            RewindButton(type: .gearshape) {
                // TODO: go to settings
            }
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
    
    private var membersTable: some View {
        MembersTable(members: Array(membersForTest.prefix(4)), isShortened: true)
    }
    
    // думаю, стоит либо сделать отдельно SectionTable, либо чуть "обобщить" InformationTable,
    // чтобы код в activityTable тоже можно было в эту таблицу обернуть, короче позже переделаю
    private var activityTable: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Activity")
                .modifier(RoundFontModifier(size: 17, foregroundColor: UIComponentsAsset.tableNameTextColor.swiftUIColor))
                .padding(.leading, 15)
            VStack(alignment: .leading, spacing: 5) {
                MembersTableButton(
                    systemImageName: "photo.on.rectangle",
                    title: "Added Rewinds stand",
                    imageSize: 20) {
                        // TODO: show stand
                    }
                
                MembersTableButton(
                    systemImageName: "forward.fill",
                    title: "Rewind rolls stand",
                    imageSize: 15) {
                        // TODO: show stand
                    }
            }
            .padding(.vertical, 5)
            .background(UIComponentsAsset.tableBackgroundColor.swiftUIColor)
            .cornerRadius(24)
        }
    }
    
    private var galleryPreview: some View {
        GalleryScrollPreview(images: images)
    }
    
    private var groupExistenceNote: some View {
        RewindNoteTextView(text: "✨ This group exists for 100 days!")
            .padding(.vertical, 4)
    }
}

#Preview {
    GroupView()
}
