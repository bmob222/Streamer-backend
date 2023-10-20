import Vapor
import Dispatch
import Logging
import LoggingLoki

/// This extension is temporary and can be removed once Vapor gets this support.
private extension Vapor.Application {
    static let baseExecutionQueue = DispatchQueue(label: "vapor.codes.entrypoint")

    func runFromAsyncMainEntrypoint() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Vapor.Application.baseExecutionQueue.async { [self] in
                do {
                    try self.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@main
enum Entrypoint {
    static func main() async throws {
        if let data = Environment.get("USER_DEFAULTS")?.data(using: .utf8),
           let json = try? JSONDecoder().decode([UserDefaultEnv].self, from: data) {
            for userDefaultObject in json {
                print("key: \(userDefaultObject.key) : \(userDefaultObject.value) ")
                UserDefaults.standard.set(userDefaultObject.value, forKey: userDefaultObject.key)
            }
        }
        var env = try Environment.detect()
        if let lokiAuth = Environment.get("LOKI_AUTH") {
            let lokiURL = URL(string: "https://logs-prod-006.grafana.net")!
            LoggingSystem.bootstrap { label in
                var lokiHandler = LokiLogHandler( label: label, lokiURL: lokiURL, headers: ["Authorization": "Basic \(lokiAuth)"])
                lokiHandler.logLevel = .trace
                return MultiplexLogHandler([
                    lokiHandler,
                    StreamLogHandler.standardOutput(label: label)
                ])
            }
        } else {
            try LoggingSystem.bootstrap(from: &env)
        }

        let app = Application(env)
        if env.isRelease {
            app.middleware.use(EncryptMiddleware())
        }
        defer { app.shutdown() }

        do {
            try configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.runFromAsyncMainEntrypoint()
    }
}
