import SwiftUI
import UIComponents

public struct FilterView: View {
    @State var viewModel: FilterViewModel
    var title: String
    var onSave: (FilterSettings) -> Void
    
    @State private var date = Date()
    @State private var invalidDatesShown = false
    
    @Environment(\.dismiss)
    private var dismiss
    
    public init(
        title: String,
        onSave: @escaping (FilterSettings) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        viewModel = FilterViewModel()
    }
    
    public var body: some View {
        ZStack {
            Color.backgroundSecondary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                    .padding(.top, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        mediasToggle
                        
                        favoritesToggle
                        
                        RewindDatePicker(
                            title: UIComponentsStrings.FilterSettings.fromDate,
                            date: $viewModel.startDate
                        )
                        
                        RewindDatePicker(
                            title: UIComponentsStrings.FilterSettings.toDate,
                            date: $viewModel.endDate
                        )
                        
                        TagsSectionView(tags: $viewModel.tags, useInvertedColors: true)
                    }
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
        .alert(
            UIComponentsStrings.FilterSettings.InvalidDates.title,
            isPresented: .constant(false),
            actions: {},
            message: { Text(UIComponentsStrings.FilterSettings.InvalidDates.message) }
        )
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
    }
    
    private var header: some View {
        RewindHeader(centerView: {
            Text(title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        })
    }
    
    private var mediasToggle: some View {
        VStack(spacing: -8) {
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.photos,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(104),
                isOn: $viewModel.photos
            )
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.videos,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(12),
                isOn: $viewModel.videos
            )
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.quotes,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(32),
                isOn: $viewModel.quotes
            )
        }
        .background(Color.background)
        .cornerRadius(22)
    }
    
    private var favoritesToggle: some View {
        RewindToggle(
            title: UIComponentsStrings.FilterSettings.Toggle.favourites,
            isOn: $viewModel.favourites
        )
        .background(Color.background)
        .cornerRadius(22)
    }
    
    private var continueButton: some View {
        GradientButton(
            title: UIComponentsStrings.FilterSettings.save,
            width: .generic
        ) {
            guard !viewModel.invalidDates else {
//                invalidDatesShown = true
                return
            }
            onSave(viewModel.generateFilters())
            dismiss()
        }
    }
}
