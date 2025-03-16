import SwiftUI

public struct GalleryHeader: View {
    private let image: UIImage
    private let groupName: String
    
    public init(image: UIImage, groupName: String) {
        self.image = image
        self.groupName = groupName
    }
    
    public var body: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) {
                // TODO: smth
            }
        } centerView: {
            HeaderBadgeView(
                image: image,
                text: groupName
            )
        } rightView: {
            GalleryMenu {
                RewindButton(type: .plus) {
                    // TODO: smth
                }
            }
        }
    }
}

#Preview {
    GalleryHeader(image: UIComponentsAsset.media5.image, groupName: "Group name")
}
