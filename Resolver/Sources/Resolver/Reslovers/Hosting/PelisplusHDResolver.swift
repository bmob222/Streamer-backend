import Foundation
import SwiftSoup

struct PelisplusHDResolver: Resolver {
    let name = "PelisplusHDResolver"
    static let domains: [String] = ["pelisplushd.nz"]
    
    enum EmpireResolverError: Error {
        case urlNotValid
    }
    
    func getMediaURL(url: URL) async throws -> [Stream] {
        let headers = [
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "DNT": "1",
            "Pragma": "no-cache",
            "Range": "bytes=393216-",
            "Referer": url.absoluteString,
            "Sec-Fetch-Dest": "video",
            "Sec-Fetch-Mode": "no-cors",
            "Sec-Fetch-Site": "same-origin",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
            "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Google Chrome\";v=\"114\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\""
        ]
        let content = try await Utilities.downloadPage(url: url, extraHeaders: headers)
        
        // Extract the JavaScript code containing "video[1]"
        if let script = try? extractJavaScriptContainingVideo(content) {
            if let videoURL = extractVideoURL(from: script) {
                let link = videoURL
                return try await HostsResolver.resolveURL(url: link)
            }
           
        }
        
        throw EmpireResolverError.urlNotValid
        
    }

    func extractJavaScriptContainingVideo(_ content: String) throws -> String {
        let pattern = #"var video = \[];.*?video\[1\] = '([^']+)';"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        if let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
            let javascript = (content as NSString).substring(with: match.range)
            return javascript
        }
        throw EmpireResolverError.urlNotValid
    }

    func extractVideoURL(from javascript: String) -> URL? {
        let pattern = #"(?<=video\[1\] = ')(https:\/\/[^']+)(?=')"#
        let regex = try! NSRegularExpression(pattern: pattern)
        if let match = regex.firstMatch(in: javascript, range: NSRange(javascript.startIndex..., in: javascript)) {
            let urlStr = (javascript as NSString).substring(with: match.range)
            return URL(string: urlStr)
        }
        return nil
    }
    
}
