import SwiftUI
import UIComponents
import Domain

public struct FilterView: View {
    @Binding var filters: FilterSettings
    var title: String
    var onSave: (FilterSettings) -> Void

    @State private var date = Date()
    @State private var invalidDatesShown = false

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast

    public init(
        title: String,
        filters: Binding<FilterSettings>,
        onSave: @escaping (FilterSettings) -> Void
    ) {
        self.title = title
        self._filters = filters
        self.onSave = onSave
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
                            date: Binding {
                                filters.startDate?.toDate()
                            } set: { newValue in
                                filters.startDate = newValue?.toString()
                            }
                        )

                        RewindDatePicker(
                            title: UIComponentsStrings.FilterSettings.toDate,
                            date: Binding {
                                filters.endDate?.toDate()
                            } set: { newValue in
                                filters.endDate = newValue?.toString()
                            }
                        )

                        tagsSection
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
        RewindHeader {
            RewindButton(type: .trash).hidden()
        } centerView: {
            Text(title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .trash) {
                withAnimation {
                    filters = .init()
                }
            }
        }
    }

    private var tagsSection: some View {
        TagsSectionView(
            tags: Binding {
                filters.tags.map { tags in tags.map { MediaTag(tag: $0) } } ?? []
            } set: { newValue in
                filters.tags = newValue.map { $0.tag }
            },
            useInvertedColors: true
        )
    }

    private var mediasToggle: some View {
        VStack(spacing: -8) {
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.photos,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(104),
                isOn: $filters.photos
            )
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.videos,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(12),
                isOn: $filters.videos
            )
            RewindToggle(
                title: UIComponentsStrings.FilterSettings.Toggle.quotes,
                description: UIComponentsStrings.FilterSettings.Toggle.mediasCount(32),
                isOn: $filters.quotes
            )
        }
        .background(Color.background)
        .cornerRadius(22)
    }

    private var favoritesToggle: some View {
        RewindToggle(
            title: UIComponentsStrings.FilterSettings.Toggle.favourites,
            isOn: Binding {
                filters.favourites ?? false
            } set: { newValue in
                filters.favourites = newValue
            }
        )
        .background(Color.background)
        .cornerRadius(22)
    }

    private var continueButton: some View {
        GradientButton(
            title: UIComponentsStrings.FilterSettings.save,
            width: .generic
        ) {
            onSave(filters)
            showToast("Filters were applied successfully! ⚙️")
            dismiss()
        }
    }
}
