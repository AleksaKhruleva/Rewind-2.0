import SwiftUI
import Domain

public struct AuthorBadgeView: View {
    private let imageURL: URL?
    private let name: String
    private let date: String
    private let track: LightTrack?

    @State private var showTrack = true
    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    public init(
        imageURL: URL?,
        name: String,
        date: String,
        track: LightTrack?
    ) {
        self.imageURL = imageURL
        self.name = name
        self.date = date
        self.track = track
    }

    public var body: some View {
        HStack(spacing: 8) {
            SquareAsyncMedia(url: imageURL, type: .image, cornerRadius: 15)
                .frame(30)

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
                            Text("\(track.artistName) — \(track.title)")
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
