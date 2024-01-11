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
        "vidhidepro.com"
    ]

    enum FilemoonResolverError: Error {
        case urlNotValid
        case codeNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let page  = try await Utilities.downloadPage(url: url)
        let decodedScript = try PackerDecoder().decode(page)
        let regx = #"file\:\"(.+?)\"\}"#
        do {
            let sourceMatchingExpr = try NSRegularExpression(
                pattern: regx,
                options: .caseInsensitive
            )
            guard let match = sourceMatchingExpr.matches(in: decodedScript).first else {
                throw FilemoonResolverError.codeNotFound
            }

            guard let aurl = URL(string: decodedScript[match, at: 1]) else {
                throw FilemoonResolverError.urlNotValid
            }

            return [.init(Resolver: url.host?.localizedCapitalized ?? "Filemoon", streamURL: aurl)]

        } catch {
            throw FilemoonResolverError.urlNotValid
        }

    }
}
