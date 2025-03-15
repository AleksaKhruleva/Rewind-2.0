//
//  BlurredAvatarTableCell.swift
//  UIComponents
//
//  Created by Danila Rakhmanov on 02.03.2025.
//

import SwiftUI

struct BlurredAvatarTableCell: View {
    var icon: String
    var title: String
    var action: () -> Void = {}
        
    public var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 25, height: 25)
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
        .onTapGesture {
            action()
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea(edges: .all)
        
        BlurredAvatarTable(showPicker: Binding.constant(false), saveImage: {})
    }
}
