import SwiftUI
import Foundation

@MainActor @Observable
final class FilterViewModel {
    var photos: Bool = true
    var videos: Bool = true
    var quotes: Bool = true
    
    var favourites: Bool = false
    
    var startDate: Date?
    var endDate: Date?
    
    var tags: [String] = []
    
    var invalidDates: Bool {
        let comparingStartDate = startDate ?? Date()
        let comparingEndDate = endDate ?? Date()
        
        return comparingStartDate >= comparingEndDate
    }
    
    public func generateFilters() -> FilterSettings {
        FilterSettings(
            photos: photos,
            videos: videos,
            quotes: quotes,
            favourites: favourites,
            startDate: startDate?.description,
            endDate: endDate?.description,
            tags: tags.isEmpty ? nil : tags
        )
    }
}
