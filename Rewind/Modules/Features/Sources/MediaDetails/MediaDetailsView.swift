import SwiftUI
import UIComponents

public struct MediaDetailsView: View {
    @State var tags: [String] = []
    private let router: AppRouter
    var image: UIImage
    
    public init(router: AppRouter, image: UIImage) {
        self.router = router
        self.image = image
    }
    
    public var body: some View {
        VStack {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rewind
                    
                    author
                        .padding(.leading)
                    
                    TagsSectionView(tags: $tags)
                    
                    riskyTable
                }
                .ignoresSafeArea()
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .padding(.horizontal, 8)
        }
        .background(Color.background)
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { router.pop() }
        } centerView: {
            Text(UIComponentsStrings.MediaDetails.title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .leftChevron).hidden()
        }
    }
    
    private var rewind: some View {
        Rectangle().toSquare(image, cornerRadius: 40)
    }
    
    private var author: some View {
        AuthorBadgeView(
            image: UIComponentsAsset.media15.image,
            name: "flowykk",
            date: "23.11.2024"
        )
    }
    
    private var riskyTable: some View {
        InformationTable(title: UIComponentsStrings.MediaDetails.risky, data: AccountConstants.risky, isRisky: true)
    }
}
