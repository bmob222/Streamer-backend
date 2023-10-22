import Vapor
import Resolver
import Redis
import Prometheus
import Metrics

func routes(_ app: Application) throws {
    enum Constants {
        static let resolveCacheExpiration: Int = 60*30
        static let providerCacheExpiration: Int = 2*60*60
    }

    struct Paging: Content {
        var page: Int?
    }

    struct Search: Content {
        var query: String
    }

    struct Debug: Content {
        var debug: String
    }

    enum CacheError: Error, Equatable {
        case noCacheFound
        case bypassCache
    }
    enum ProviderError: Error, Equatable {
        case emptyResponse
    }

    app.get("") { _ async throws -> String in
        return "Welcome to Streamer!"
    }
    app.get("metrics") { _ async throws -> String in
        return try await MetricsSystem.prometheus().collect()
    }

    app.get("providers", ":provider", "home") { req -> [Resolver.MediaContentSection] in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString) else {
            throw Abort(.badRequest)
        }

        let provider = ProviderType.local(id: localProvider).provider
        incCounter(provider: localProvider.rawValue, type: "home")
        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: [Resolver.MediaContentSection].self) else {
                    throw CacheError.noCacheFound
                }
                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let response = try await provider.home()
            if response.count > 0 {
                if app.environment == .production {
                    Task {
                        try await app.redis.setex(
                            RedisKey(req.url.string),
                            toJSON: response,
                            expirationInSeconds: Constants.providerCacheExpiration
                        )
                    }
                }
                return response

            } else {
                throw ProviderError.emptyResponse
            }
        }
    }

    app.get("providers", ":provider", "movies") { req -> [Resolver.MediaContent] in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString) else {
            throw Abort(.badRequest)
        }

        let provider = ProviderType.local(id: localProvider).provider
        incCounter(provider: localProvider.rawValue, type: "movies-listing")
        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: [Resolver.MediaContent].self) else {
                    throw CacheError.noCacheFound
                }

                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let page = try req.query.decode(Paging.self).page ?? 1
            let response =  try await provider.latestMovies(page: page)
            if app.environment == .production {
                Task {
                    try await app.redis.setex(
                        RedisKey(req.url.string),
                        toJSON: response,
                        expirationInSeconds: Constants.providerCacheExpiration
                    )
                }
            }
            return response

        }

    }

    app.get("providers", ":provider", "movies", ":movieId") { req -> Resolver.Movie in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString),
              let movieID = req.parameters.get("movieId"),
              let base64URL = movieID.fromBase64URL(),
              let movieURL = URL(string: base64URL)
        else {
            throw Abort(.badRequest)
        }

        let provider = ProviderType.local(id: localProvider).provider
        incCounter(provider: localProvider.rawValue, type: "movies-details")
        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: Resolver.Movie.self) else {
                    throw CacheError.noCacheFound
                }
                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let response = try await provider.fetchMovieDetails(for: movieURL)
            if app.environment == .production {
                Task {
                    try await app.redis.setex(
                        RedisKey(req.url.string),
                        toJSON: response,
                        expirationInSeconds: Constants.providerCacheExpiration
                    )
                }
            }
            return response
        }
    }

    app.get("providers", ":provider", "tv") { req -> [Resolver.MediaContent] in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString) else {
            throw Abort(.badRequest)
        }

        let provider = ProviderType.local(id: localProvider).provider
        incCounter(provider: localProvider.rawValue, type: "tv-listing")

        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: [Resolver.MediaContent].self) else {
                    throw CacheError.noCacheFound
                }
                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let page = try req.query.decode(Paging.self).page ?? 1
            let response =  try await provider.latestTVShows(page: page)
            if response.count > 0 {
                if app.environment == .production {
                    Task {
                        try await app.redis.setex(
                            RedisKey(req.url.string),
                            toJSON: response,
                            expirationInSeconds: Constants.providerCacheExpiration
                        )
                    }
                }
                return response
            } else {
                throw ProviderError.emptyResponse
            }
        }
    }

    app.get("providers", ":provider", "tv", ":tvID") { req -> Resolver.TVshow in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString),
              let tvID = req.parameters.get("tvID"),
              let base64URL = tvID.fromBase64URL(),
              let tvURL = URL(string: base64URL)
        else {
            throw Abort(.badRequest)
        }
        let provider = ProviderType.local(id: localProvider).provider
        incCounter(provider: localProvider.rawValue, type: "tv-details")

        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: Resolver.TVshow.self) else {
                    throw CacheError.noCacheFound
                }
                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let response = try await provider.fetchTVShowDetails(for: tvURL)
            if app.environment == .production {
                Task {
                    try await app.redis.setex(
                        RedisKey(req.url.string),
                        toJSON: response,
                        expirationInSeconds: Constants.providerCacheExpiration
                    )
                }
            }
            return response
        }
    }

    app.get("providers", ":provider", "search") { req -> [Resolver.MediaContent] in
        guard let providerString = req.parameters.get("provider"),
              let localProvider = LocalProvider(rawValue: providerString)
        else {
            throw Abort(.badRequest)
        }
        incCounter(provider: localProvider.rawValue, type: "search")
        let provider = ProviderType.local(id: localProvider).provider

        do {
            if app.environment == .production {
                guard let response = try await app.redis.get(RedisKey(req.url.string), asJSON: [Resolver.MediaContent].self) else {
                    throw CacheError.noCacheFound
                }
                return response
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let query = try req.query.decode(Search.self).query
            let response =  try await provider.search(keyword: query, page: 1)
            if app.environment == .production {
                Task {
                    if response.count > 0 {
                        try await app.redis.setex(
                            RedisKey(req.url.string),
                            toJSON: response,
                            expirationInSeconds: Constants.providerCacheExpiration
                        )
                    }
                }
            }
            return response
        }
    }

    app.get("reslover", ":id") { req -> [Resolver.Stream] in
        guard let id = req.parameters.get("id")?.fromBase64URL(),
              let url = URL(string: id) else {
            throw Abort(.badRequest)
        }
        if let resolver = HostsResolver.ResolverName(url: url) {
            let counter = try? MetricsSystem.prometheus().createCounter(forType: Int.self, named: "links_resolved")
            counter?.inc(1, DimensionLabels(arrayLiteral: ("resolver", resolver)))
        }

        do {
            if app.environment == .production {
                guard let streams = try await app.redis.get(RedisKey(req.url.string), asJSON: [Resolver.Stream].self) else {
                    throw CacheError.noCacheFound
                }
                return streams
            } else {
                throw Abort(.badRequest)
            }
        } catch {
            let streams = try await HostsResolver.resolveURL(url: url)

            if streams.count > 0 {
                if app.environment == .production {
                    Task {
                        try await app.redis.setex(
                            RedisKey(req.url.string),
                            toJSON: streams,
                            expirationInSeconds: Constants.resolveCacheExpiration
                        )
                    }
                }
            }
            return streams
        }

    }
    app.get("tmdb", "movie", ":movieId") { req -> [Resolver.Source] in
        guard let id = req.parameters.get("movieId"),
              let tmdbID = Int(id),
              let themoviearchiveURL = URL(string: "https://prod.omega.themoviearchive.site/v3/movie/sources/\(tmdbID)") else {
            throw Abort(.badRequest)
        }
        return [
            .init(hostURL: themoviearchiveURL)
        ]
    }

    app.get("tmdb", "tv", ":tvShowID", ":seasonNumber", ":episodeNumber") { req -> [Resolver.Source] in
        guard
            let id = req.parameters.get("tvShowID"),
            let tmdbID = Int(id),
            let seasonNumberString = req.parameters.get("seasonNumber"),
            let seasonNumber = Int(seasonNumberString),
            let episodeNumberString = req.parameters.get("episodeNumber"),
            let episodeNumber = Int(episodeNumberString)
        else {
            throw Abort(.badRequest)
        }
        return []
    }

    func incCounter(provider: String, type: String) {
        let counter = try? MetricsSystem.prometheus().createCounter(forType: Int.self, named: "provider_request")
        counter?.inc(1, DimensionLabels(arrayLiteral: ("provider", provider), ("type", type)))
    }
}

extension Resolver.MediaContentSection: Content {

}
extension Resolver.Stream: Content {

}

extension Resolver.MediaContent: Content {

}
extension Resolver.Movie: Content {

}
extension Resolver.TVshow: Content {

}

extension Resolver.Source: Content {

}
