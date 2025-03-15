import SwiftUI

public struct AvatarView: View {
    let image: UIImage
    let text: String
    
    public init(image: UIImage?, text: String) {
        self.image = image ?? UIImage(systemName: "person.fill")!
        self.text = text
    }
    
    public var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .cornerRadius(65)
            
            Text("flowykk")
                .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
                .font(.system(size: 20, weight: .black, design: .rounded))
        }
    }
}

#Preview {
    AvatarView(image: UIImage(named: "avatar"), text: "flowykk")
}
