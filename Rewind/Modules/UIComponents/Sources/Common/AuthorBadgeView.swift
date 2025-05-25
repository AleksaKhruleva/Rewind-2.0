import SwiftUI
import Domain

public struct AuthorBadgeView: View {
    private let image: UIImage
    private let name: String
    private let date: String
    private let track: Track?

    @State private var showTrack = true
    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    public init(image: UIImage, name: String, date: String, track: Track? = nil) {
        self.image = image
        self.name = name
        self.date = date
        self.track = track
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .cornerRadius(20)

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .modifier(RoundFontModifier(
                        size: 14,
                        weight: .black,
                        foregroundColor: .textPrimary
                    ))

                Group {
                    if let track, showTrack {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                            Text("\(track.artist) — \(track.title)")
                                .lineLimit(1)
                        }
                    } else {
                        Text(date)
                    }
                }
                .transition(.opacity)
                .modifier(RoundFontModifier(
                    size: 10,
                    weight: .black,
                    foregroundColor: .textTertiary
                ))
                .animation(.easeInOut(duration: 0.5), value: showTrack)
            }
        }
        .onReceive(timer) { _ in
            if track != nil {
                withAnimation {
                    showTrack.toggle()
                }
            }
        }
    }
}

#Preview {
    AuthorBadgeView(
        image: UIComponentsAsset.media15.image,
        name: "flowykk",
        date: "23.11.2024"
    )
}
