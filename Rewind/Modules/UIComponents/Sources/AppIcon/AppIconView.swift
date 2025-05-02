import SwiftUI

public struct AppIconView: View {
    @State var viewModel: AppIconViewModel

    public init(viewModel: AppIconViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            icon
            
            availability
            
            if viewModel.locked {
                taskTitle
            }
        }
    }
    
    public var icon: some View {
        Image(viewModel.name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 70, height: 70)
            .cornerRadius(18)
    }
    
    @ViewBuilder
    public var availability: some View {
        Group {
            if viewModel.selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color(.systemGreen)).frame(width: 24, height: 24))
            } else if viewModel.locked {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.gray)
                    .background(Circle().fill(.white).frame(width: 24, height: 24))
            } else {
                EmptyView()
            }
        }
        .fontWeight(.bold)
        .offset(x: 25, y: -25)
    }
    
    public var taskTitle: some View {
        Text(viewModel.task)
            .modifier(AppIconTaskModifier())
    }
}
