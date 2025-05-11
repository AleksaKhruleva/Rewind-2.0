import Moya
import Foundation

final class NetworkProvider<T: TargetType> {
    private let provider: MoyaProvider<T>
    
    init(stub: Bool = false, timeout: TimeInterval = 5) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        
        self.provider = MoyaProvider<T>(
            stubClosure: stub ? MoyaProvider.immediatelyStub : MoyaProvider.neverStub,
            session: Session(configuration: configuration)
        )
    }

    func request<D: Decodable>(_ target: T, type: D.Type) async throws -> D {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    guard response.statusCode >= 200 && response.statusCode < 300 else {
                        print(HTTPError(statusCode: response.statusCode, reason: response.debugDescription))
                        continuation.resume(throwing: HTTPError(statusCode: response.statusCode, reason: response.debugDescription))
                        return
                    }
                    do {
                        let decoded = try JSONDecoder().decode(D.self, from: response.data)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
