import Domain
import Foundation

public protocol SoundCloudServiceProtocol {
    func fetchCharts(limit: Int) async throws -> ChartsResponse
    func fetchStreamURL(for track: Track) async throws -> URL?
    func searchTracks(query: String, limit: Int) async throws -> TracksResponse
    func fetchNextPage(from href: String) async throws -> TracksResponse
}

public final class SoundCloudNetworkService: SoundCloudServiceProtocol {
    private let provider = NetworkProvider<SoundCloudService>()
    
    public init() {}
    
    public func fetchCharts(limit: Int) async throws -> ChartsResponse {
        let response = try await provider.request(
            .fetchCharts(
                kind: "top",
                genre: "soundcloud:genres:all-music",
                offset: 0,
                limit: limit
            ),
            type: ChartsResponse.self
        )
        
        let filtered = response.collection.filter { isProgressive($0.track) }
        
        return ChartsResponse(
            collection: filtered,
            next_href: response.next_href
        )
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
    
    public func searchTracks(query: String, limit: Int) async throws -> TracksResponse {
        let response = try await provider.request(
            .searchTracks(query: query, limit: limit),
            type: TracksResponse.self
        )
        
        return TracksResponse(
            collection: response.collection.filter(isProgressive),
            next_href: response.next_href
        )
    }
    
    public func fetchNextPage(from href: String) async throws -> TracksResponse {
        guard var components = URLComponents(string: href) else {
            throw URLError(.badURL)
        }
        
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "client_id", value: "ha0UP7nWZvg1nBR5ZfoRsMC7GXi4Qe6x"))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let response = try await provider.request(
            .fetchNextPage(from: url),
            type: TracksResponse.self
        )
        
        return TracksResponse(
            collection: response.collection.filter(isProgressive),
            next_href: response.next_href
        )
    }
    
    // MARK: - Helper
    
    private func isProgressive(_ track: Track) -> Bool {
        track.media?.transcodings.contains {
            $0.format.`protocol` == "progressive"
        } ?? false
    }
}
