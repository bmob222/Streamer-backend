import Foundation
import SwiftSoup

struct MovieBoxResolver: Resolver {
    let name = "MovieBox Pro"
    static let domains: [String] = ["showbox.host"]

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("showbox.") == true
    }

    @EnviromentValue(key: "subtitles_srt_url", defaultValue: URL(staticString: "https://google.com/"))
    var subtitlesBaseURL

    enum AnimetvStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let data = try await Utilities.requestData(url: url)
        let content = try JSONCoder.decoder.decode(Response.self, from: data)

        return try await content.data.list.concurrentMap { item -> Stream? in
            guard let playUrl = URL(string: item.path) else { return nil }

            let subtitlesURL = url.appendingPathComponent("srt").appendingPathComponent(item.fid)
            let data = try await Utilities.requestData(url: subtitlesURL)

            let content = try JSONCoder.decoder.decode(SubtitleResponse.self, from: data)

            let subtitles = content.data.list.compactMap { section in
                return section.subtitles.map {
                    let srtPath = subtitlesBaseURL.appendingQueryItem(name: "url", value: $0.filePath)
                    return Subtitle(url: srtPath, language: .init(rawValue: section.language) ?? .english)
                }
            }.flatMap { $0 }

            var name = item.quality == "org" ? "MovieBox Original" : "MovieBox"
            name = name + ( item.hdr == 1 ? " HDR" : "")
            return Stream(Resolver: name, streamURL: playUrl, quality: Quality(quality: item.realQuality), subtitles: subtitles)
        }
        .compactMap { $0 }
    }
    // MARK: - Welcome
    struct Response: Codable {
        let data: DataClass
    }

    // MARK: - DataClass
    struct DataClass: Codable {
        let list: [List]
    }

    // MARK: - List
    struct List: Codable {
        let path: String
        let quality: String
        let realQuality: String
        let fid: Int
        let hdr: Int

        enum CodingKeys: String, CodingKey {
            case path
            case quality
            case realQuality = "real_quality"
            case fid
            case hdr
        }

    }

    struct SubtitleResponse: Codable {
        let data: SubtitleDataClass
    }

    // MARK: - DataClass
    struct SubtitleDataClass: Codable {
        let list: [SubtitleList]
    }
    // MARK: - List
    struct SubtitleList: Codable {
        let language: String
        let subtitles: [SubtitleItem]

    }
    struct SubtitleItem: Codable {
        let filePath: String

        enum CodingKeys: String, CodingKey {
            case filePath = "file_path"
        }
    }

}
