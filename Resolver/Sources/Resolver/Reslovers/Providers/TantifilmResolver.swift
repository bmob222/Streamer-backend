
    import Foundation
    import SwiftSoup
    
    struct TantifilmResolver: Resolver {
        let name = "Tantifilm"
        static let domains: [String] = ["nuovo-indirizzo.com","hdplayer.casa"]
        
        enum YugenAnimeResolverError: Error {
            case urlNotValid, contentFetchingError, parsingError
        }
        
        func getMediaURL(url: URL) async throws -> [Stream] {
            // Fetch and parse the main content
            guard let content = try? await Utilities.downloadPage(url: url) else {
                throw YugenAnimeResolverError.contentFetchingError
            }
            let document = try SwiftSoup.parse(content)
            
            // Extract the src attribute of the iframe with id "main-embed"
            let iframeSrcs = try document.select("iframe").array().map {
                try $0.attr("src")
            }
            
            // Convert relative URLs to absolute URLs and filter out invalid ones
            return try await iframeSrcs.compactMap { src -> URL? in
                guard var absoluteSrc = URL(string: src, relativeTo: url)?.absoluteString else {
                    throw YugenAnimeResolverError.urlNotValid
                }
                if src.starts(with: "//") {
                    absoluteSrc = "https:" + src
                }
                return URL(string: absoluteSrc)
            }.concurrentMap {
                return try? await HostsResolver.resolveURL(url: $0)
            }
            .compactMap { $0 }
            .flatMap { $0 }
            
           
            
        }
    }

