import Foundation
import SwiftSoup

struct AkwamResolver: Resolver {
    let name = "Akwam"
    static let domains: [String] = ["akwam.us", "akw.to", "re.two.re", "ak.sv"]
    private let baseURL: URL = URL(string: "https://akwam.us/")!

    enum AkwamResolverError: Error {
        case urlNotValid
    }
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("akwam") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))
        let epPaths = url.absoluteString.contains("show") ? url.pathComponents.dropFirst(3) : url.pathComponents.dropFirst(2)

        // link-show

        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".link-show")
        let shortURLs = rows.array().compactMap { row -> URL? in
            if let url = try? row.attr("href") {
                return URL(string: url)
            } else {
                return nil
            }
        }
        .filter { $0.absoluteString.contains("/watch/")}
        .map {
            $0.pathComponents + epPaths
        }
        .map {
            baseURL.appendingPathComponent($0.joined(separator: "/"))
        }

        for url in shortURLs {
            let streams = try await getMp4Link(url: url)
            guard !streams.isEmpty  else {
                continue
            }
            return streams
        }

        throw AkwamResolverError.urlNotValid
    }

    private func getMp4Link(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: Utilities.workerURL(url))

        let document = try SwiftSoup.parse(content)
        let links: Elements = try document.select("source[src]") // a with href

        return links.array().compactMap { row in
            try? row.attr("src")
        }
        .compactMap {
            URL(string: $0)
        }
        .map {
            .init(Resolver: "Akwam", streamURL: $0)
        }
    }

}
