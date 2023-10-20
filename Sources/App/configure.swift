import Vapor
import Redis
import Resolver
import Prometheus
import Metrics

public func configure(_ app: Application) throws {
    if let redisURL = Environment.get("REDIS_URL") {
        app.redis.configuration = try RedisConfiguration(url: redisURL)
    }
    Resolver.logger = app.logger
    HostsResolver.remove(Environment.get("SKIPPED_RESOLVERS") ?? "")

    let myProm = PrometheusClient()
    MetricsSystem.bootstrap(PrometheusMetricsFactory(client: myProm))
    try routes(app)
}

struct UserDefaultEnv: Codable {
    let key: String
    let value: String
}
