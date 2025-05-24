import Moya
import Foundation

private let clientID = "ha0UP7nWZvg1nBR5ZfoRsMC7GXi4Qe6x"

enum SoundCloudService {
    case fetchCharts(kind: String, genre: String, offset: Int, limit: Int)
    case fetchStreamURL(url: URL)
    case searchTracks(query: String, limit: Int)
    case fetchNextPage(from: URL)
}

extension SoundCloudService: TargetType {
    var baseURL: URL {
        switch self {
        case .fetchCharts, .searchTracks:
            return URL(string: "https://api-v2.soundcloud.com")!
        case let .fetchStreamURL(url), let .fetchNextPage(url):
            return url.deletingLastPathComponent()
        }
    }

    var path: String {
        switch self {
        case .fetchCharts:
            return "/charts"
        case .searchTracks:
            return "/search/tracks"
        case let .fetchStreamURL(url), let .fetchNextPage(url):
            return url.lastPathComponent
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case let .fetchCharts(kind, genre, offset, limit):
            return .requestParameters(
                parameters: [
                    "kind": kind,
                    "genre": genre,
                    "offset": offset,
                    "limit": limit,
                    "client_id": clientID
                ],
                encoding: URLEncoding.default
            )

        case .fetchStreamURL:
            return .requestParameters(
                parameters: [
                    "client_id": clientID
                ],
                encoding: URLEncoding.default
            )

        case let .searchTracks(query, limit):
            return .requestParameters(
                parameters: [
                    "q": query,
                    "limit": limit,
                    "client_id": clientID
                ],
                encoding: URLEncoding.default
            )

        case .fetchNextPage:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}
