import Vapor

struct MockBackend {
    var app: Application
    
    init(configuration: (RoutesBuilder) throws -> Void) throws {
        app = Application(.testing)
        try configuration(app.routes)
    }
    
    func launch() {
        Task {
            try await app.execute()
        }
    }
    
    func shutdown() {
        app.shutdown()
    }
}
