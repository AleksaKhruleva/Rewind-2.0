import Domain
import Foundation

public protocol SoundCloudServiceProtocol {
    func fetchCharts(limit: Int) async throws -> [Track]
    func fetchStreamURL(for track: Track) async throws -> URL?
    func searchTracks(query: String) async throws -> [Track]
}

public final class SoundCloudNetworkService: SoundCloudServiceProtocol {
    private let provider = NetworkProvider<SoundCloudService>()
    
    public init() {}
    
    public func fetchCharts(limit: Int) async throws -> [Track] {
        let response = try await provider.request(
            .fetchCharts(
                kind: "top",
                genre: "soundcloud:genres:all-music",
                offset: 0,
                limit: limit
            ),
            type: ChartsResponse.self
        )
        
        return response.collection
            .map(\.track)
            .filter { track in
                track.media?.transcodings.contains(where: {
                    $0.format.`protocol` == "progressive"
                }) ?? false
            }
    }
    
    
    public func fetchStreamURL(for track: Track) async throws -> URL? {
        guard let progressive = track.media?.transcodings.first(where: {
            $0.format.`protocol` == "progressive"
        }) else {
            return nil
        }
        
        let response = try await provider.request(
            .fetchStreamURL(url: progressive.url),
            type: [String: URL].self
        )
        
        return response["url"]
    }
    
    public func searchTracks(query: String) async throws -> [Track] {
        let response = try await provider.request(
            .searchTracks(query: query),
            type: TracksResponse.self
        )
        
        return response.collection
            .filter { track in
                track.media?.transcodings.contains(where: {
                    $0.format.`protocol` == "progressive"
                }) ?? false
            }
    }
}
