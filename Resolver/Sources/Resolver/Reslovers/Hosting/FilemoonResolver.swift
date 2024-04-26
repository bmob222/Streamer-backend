import Foundation

struct FilemoonResolver: Resolver {
    let name = "Filemoon"
    static let domains: [String] = [
        "filemoon.sx",
        "filemoon.to",
        "alions.pro",
        "filelions.com",
        "filelions.to",
        "ajmidyadfihayh.sbs",
        "alhayabambi.sbs",
        "techradar.ink",
        "moflix-stream.click",
        "azipcdn.com",
        "mlions.pro",
        "alions.pro",
        "dlions.pro",
        "filelions.live",
        "motvy55.store",
        "filelions.xyz",
        "lumiawatch.top",
        "filelions.online",
        "javplaya.com",
        "fviplions.com",
        "egsyxutd.sbs",
        "filelions.site",
        "vidhidepro.com",
        "streamvid.net",
        "fsdcmo.sbs",
        "lylxan.com",
        "luluvdo.com",
        "vidhidevip.com",
        "kerapoxy.cc",
        "vpcxz19p.xyz",
        "filemoon.top",
        "fmoonembed.pro",
        "rgeyyddl.skin"
    ]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func getMediaURL(url: URL) async throws -> [Stream] {
        let url = url.removing("sub.info")
        let info = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appendingPathComponent("filemoon").appending("url", value: info.encodeURIComponent())

        do {

            let data = try await Utilities.requestData(url: eURL)
            let content = try JSONDecoder().decode(VidPlay.self, from: data)
            return content.stream.compactMap {

                Stream(
                    Resolver: "Filemoon",
                    streamURL: $0.playlist,
                    subtitles: $0.captions.map { .init(url: $0.url, language: .init(rawValue: $0.language) ?? .unknown)})
            }
        } catch {
            print(error)
            throw error
        }

    }

    // MARK: - VidPlay
    struct VidPlay: Codable {
        let stream: [SStream]

        enum CodingKeys: String, CodingKey {
            case stream = "stream"
        }
    }

    // MARK: - Stream
    struct SStream: Codable {
        let playlist: URL
        let headers: Headers?
        let captions: [Caption]

        enum CodingKeys: String, CodingKey {
            case playlist = "playlist"
            case headers = "headers"
            case captions = "captions"
        }
    }

    // MARK: - Caption
    struct Caption: Codable {
        let url: URL
        let language: String

        enum CodingKeys: String, CodingKey {
            case url = "url"
            case language = "language"
        }
    }

    // MARK: - Headers
    struct Headers: Codable {
        let referer: String
        let origin: String

        enum CodingKeys: String, CodingKey {
            case referer = "Referer"
            case origin = "Origin"
        }
    }
}
