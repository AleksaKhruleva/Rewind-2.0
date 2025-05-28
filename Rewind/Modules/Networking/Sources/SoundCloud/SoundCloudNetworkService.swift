import Domain
import Foundation

public enum TrackSource {
    case charts
    case search
}

public protocol SoundCloudServiceProtocol {
    func fetchCharts(limit: Int) async throws -> TracksResponse
    func fetchStreamURL(for track: Track) async throws -> URL?
    func fetchStreamURL(for lightTrack: LightTrack) async throws -> URL?
    func searchTracks(query: String, limit: Int) async throws -> TracksResponse
    func fetchNextPage(from href: String, for source: TrackSource) async throws -> TracksResponse
    func fetchTrack(by id: String) async throws -> LightTrackResponse
}

public final class SoundCloudNetworkService: SoundCloudServiceProtocol {
    private let provider = NetworkProvider<SoundCloudService>(timeout: 15)

    public init() {}

    public func fetchTrack(by id: String) async throws -> LightTrackResponse {
        try await provider.request(
            .fetchTrack(id: id),
            type: LightTrackResponse.self
        )
    }

    public func fetchCharts(limit: Int) async throws -> TracksResponse {
        let response = try await provider.request(
            .fetchCharts(
                kind: "top",
                genre: "soundcloud:genres:all-music",
                offset: 0,
                limit: limit
            ),
            type: ChartsResponse.self
        )

        return TracksResponse(
            collection: response.collection.map(\.track).filter(isProgressive),
            next_href: response.next_href
        )
    }

    public func fetchStreamURL(for track: Track) async throws -> URL? {
        guard let progressive = track.media?.transcodings.first(where: {
            $0.format.protocolType == "progressive"
        }) else {
            return nil
        }

        let response = try await provider.request(
            .fetchStreamURL(url: progressive.url),
            type: [String: URL].self
        )

        return response["url"]
    }

    public func fetchStreamURL(for lightTrack: LightTrack) async throws -> URL? {
        guard let progressive = lightTrack.media?.transcodings.first(where: {
            $0.format.protocolType == "progressive"
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

    public func fetchNextPage(from href: String, for source: TrackSource) async throws -> TracksResponse {
        guard var components = URLComponents(string: href) else {
            throw URLError(.badURL)
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "client_id", value: "CQzyZQR9J1A6DwlJEpfEiEDQbCbwOMfu"))
        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        switch source {
        case .charts:
            let response = try await provider.request(
                .fetchNextPage(from: url),
                type: ChartsResponse.self
            )
            return TracksResponse(
                collection: response.collection.map(\.track).filter(isProgressive),
                next_href: response.next_href
            )

        case .search:
            let response = try await provider.request(
                .fetchNextPage(from: url),
                type: TracksResponse.self
            )
            return TracksResponse(
                collection: response.collection.filter(isProgressive),
                next_href: response.next_href
            )
        }
    }

    // MARK: - Helper

    private func isProgressive(_ track: Track) -> Bool {
        track.media?.transcodings.contains {
            $0.format.protocolType == "progressive"
        } ?? false
    }
}
