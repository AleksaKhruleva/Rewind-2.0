import SwiftUI

// Выпилить позже
public struct MusicCell: View {
    var cover: UIImage
    var trackName: String
    var artist: String
    var action: () -> Void
    
    public init(cover: UIImage, trackName: String, artist: String, action: @escaping () -> Void) {
        self.cover = cover
        self.trackName = trackName
        self.artist = artist
        self.action = action
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(uiImage: cover)
                .resizable()
                .scaledToFill()
                .frame(40)
                .cornerRadius(10)
            
            Text("\(artist) - \(trackName)")
                .modifier(RoundFontModifier(
                    size: AccountConstants.defaultFontSize,
                    weight: .bold,
                    foregroundColor: .textPrimary
                ))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 17))
                .fontWeight(.bold)
                .frame(width: 30, height: 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
