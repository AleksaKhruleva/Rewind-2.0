//
//  AuthorBadgeView.swift
//  UIComponents
//
//  Created by Danila Rakhmanov on 15.03.2025.
//

import SwiftUI

struct AuthorBadgeView: View {
    private let image: UIImage
    private let name: String
    private let date: String
    
    public init(image: UIImage, name: String, date: String) {
        self.image = image
        self.name = name
        self.date = date
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .cornerRadius(20)
            
            VStack(alignment: .leading) {
                Text(name)
                    .modifier(RoundFontModifier(
                            size: 14,
                            weight: .black,
                            foregroundColor: UIComponentsAsset.primaryColor.swiftUIColor
                        ))
                
                Text(date)
                    .modifier(RoundFontModifier(
                            size: 10,
                            weight: .black,
                            foregroundColor: UIComponentsAsset.secondaryColor.swiftUIColor
                        ))
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
