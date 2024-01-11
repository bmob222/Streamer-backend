import Foundation

protocol Resolver {
    static var domains: [String] { get }
    var name: String { get }
    func getMediaURL(url: URL) async throws -> [Stream]
    func canHandle(url: URL) -> Bool
}
extension Resolver {
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil
    }
}

public struct HostsResolver {
    static var Resolvers: [ Resolver ] = [
        AkwamResolver(),
        CimaNowResolver(),
        DoodstreamResolver(),
        EmbedsitoResolver(),
        FlixtorResolver(),
        MixdropResolver(),
        MoplayResolver(),
        MyCloudResolver(),
        KaidoResolver(),
        NuploadResolver(),
        PelisflixResolver(),
        PelisplusResolver(),
        PelisplussResolver(),
        RabbitstreamResolver(),
        SeriesYonkisResolver(),
        StreamlareResolver(),
        StreamSBResolver(),
        StreamtapeResolver(),
        TwoEmbedResolver(),
        UqloadResolver(),
        VidCloud9Resolver(),
        VideovardResolver(),
        VidsrcResolver(),
        FilemoonResolver(),
        StreamingCommunityResolver(),
        OlgPlayResolver(),
        DatabasegdriveplayerResolver(),
        WatchSBResolver(),
        ArabSeedResolver(),
        FlixHQResolver(),
        ViewAsianResolver(),
        WolfstreamResolver(),
        FilmPalastResolver(),
        VoeResolver(),
        StreamflixResolver(),
        AnimetvStreamResolver(),
        BestXStreamResolver(),
        MyFileStorageResolver(),
        PutlockerResolver(),
        Fstream365Resolver(),
        FaselHDResolver(),
        MovieBoxResolver(),
        ShowBoxResolver(),
        EmpireResolver(),
        EplayerResolver(),
        StreamWishResolver(),
        GogoAnimeHDResolver(),
        TheMovieArchiveReslover(),
        AniwatchReslover(),
        GogoCDNResolver(),
        Mp4UploadReslover(),
        SuperflixReslover(),
        WeCimaReslover(),
        AniworldResolver(),
        AnixAnimeResolver(),
        YugenAnimeResolver(),
        UprotReslover(),
        VembedNetResolver()
    ]
    static public func resolveURL(url: URL) async throws -> [Stream] {
        logger.info("🕸 Resolving \(url)")
        guard url.host != nil else {
            return []
        }
        let Resolvers = Self.Resolvers.filter({ $0.canHandle(url: url)})
        guard !Resolvers.isEmpty else {
            logger.error("URL host not supported : \(url.absoluteString)")
            throw ResolverError.hostNotSupported
        }

        return try await Resolvers.concurrentMap {Resolver in
            logger.info("Using Resolver: \(Resolver.name)")
            return try await Resolver.getMediaURL(url: url)
                .concurrentMap {
                    if $0.streamURL.absoluteString.contains("m3u8"), $0.quality == .unknown {
                        if let stream = try? await M3u8Parser.getQuality(stream: $0) {
                            return stream
                        } else {
                            return $0
                        }
                    } else {
                        return $0
                    }
                }
        }
        .compactMap { $0 }
        . flatMap { $0 }

    }

    static public func ResolverName(url: URL) -> String? {
        guard let Resolver = Self.Resolvers.filter({ $0.canHandle(url: url)}).first else {
            return nil
        }
        return Resolver.name

    }

    static public func remove(_ providers: String) {
        let skippedResolvers = providers.components(separatedBy: ",")
        Resolvers.removeAll(where: {
            skippedResolvers.contains($0.name)
        })
    }
}

public enum ResolverError: Error {
    case hostError
    case hostNotSupported
    case URLNotFound
    case NoStreamsFound
}
