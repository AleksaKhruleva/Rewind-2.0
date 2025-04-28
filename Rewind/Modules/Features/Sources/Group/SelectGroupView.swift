import SwiftUI
import UIComponents

// временно
let imageSize: CGFloat = 90

// временно
let groupNames = [
    "Friends",
    "Family",
    "Work",
    "Travel",
    "Fitness",
    "Photography",
    "Study",
    "Music",
    "Foodies"
]

// временно
let groupsForTest: [RewindGroup] = zip(images, groupNames).map { image, name in
    RewindGroup(image: image, name: name)
}

struct SelectGroupView: View {
    @State private var searchText = ""
    
    private var filteredGroups: [RewindGroup] {
        if searchText.isEmpty {
            return groupsForTest
        } else {
            return groupsForTest.filter { group in
                group.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        ZStack {
            UIComponentsAsset.tableBackgroundColor.swiftUIColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select group")
                    .modifier(RoundFontModifier(size: 21))
                
                searchField
                
                groupsScroll
                
                suggestionsTable
            }
            .padding(.horizontal)
        }
    }
    
    private var searchField: some View {
        RewindSearchField(
            text: $searchText,
            placeholder: "Group's name",
            backgroundColor: .white
        )
    }
    
    private var groupsScroll: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(images.count) groups")
                .modifier(RoundFontModifier(size: 17, foregroundColor: UIComponentsAsset.tableNameTextColor.swiftUIColor))
                .padding(.leading, 16)
            
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(.white)
                
                GroupsScrollView(groups: filteredGroups, imageSize: imageSize)
                    .frame(height: imageSize + 20)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .padding(.horizontal, 15)
            }
            .frame(height: imageSize + 40)
        }
    }
    
    // временно
    private var suggestionsTable: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Suggestions")
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        foregroundColor: UIComponentsAsset.tableNameTextColor.swiftUIColor
                    )
                )
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                suggestionRow(icon: "plus", title: "Add group")
                suggestionRow(icon: "person.2.fill", title: "\(images.count) groups")
            }
            .background(.white)
            .cornerRadius(20)
        }
    }
    
    // временно
    private func suggestionRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .modifier(RoundFontModifier(size: 20))
                .frame(width: 34, height: 34)
            
            Text(title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .modifier(RoundFontModifier(size: 17))
                .frame(width: 30, height: 30)
        }
        .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
        .contentShape(Rectangle())
        .frame(height: 50)
        .padding(.horizontal)
    }
}

#Preview {
    SelectGroupView()
}
