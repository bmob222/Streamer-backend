import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Utilities {

    static public var userID: String?
    static public var appVersion: String?
    static public var device: String?

    @EnviromentValue(
        key: "streamer_backend_key",
        defaultValue: "green"
    )
    static public var streamerBEkey: String

    @EnviromentValue(
        key: "worker_url",
        defaultValue: URL(staticString: "https://silent-mud-a06e.admin505.workers.dev/")
    )
    static public var workerURL: URL

    @EnviromentValue(
        key: "cloud_flare_url",
        defaultValue: URL(staticString: "https://google.com")
    )
    static public var cloudFlareResolver: URL

    static func workerURL(_ url: URL) -> URL {
        return workerURL.appending(["url": url.absoluteString])
    }

    public static func extractURLs(content: String) -> [URL] {
        let pattern = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)" +
        "(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*" +
        "\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
        return content.matches(for: pattern).compactMap {
            URL(string: $0)
        }
    }
    public static func requestData(
        url: URL,
        httpMethod: String = "GET",
        parameters: [String: String] = [:],
        data: Data? = nil,
        extraHeaders: [String: String] = [:],
        solveCaptcha: Bool = true) async throws -> Data {
            try await Self.requestResponse(url: url, httpMethod: httpMethod, parameters: parameters, data: data, extraHeaders: extraHeaders, solveCaptcha: solveCaptcha).0
        }

    public static func requestResponse(
        url: URL,
        httpMethod: String = "GET",
        parameters: [String: String] = [:],
        data: Data? = nil,
        extraHeaders: [String: String] = [:],
        solveCaptcha: Bool = true) async throws -> (Data, URLResponse) {
            ResolverURLSession.shared.session.configuration.httpCookieStorage = .shared
            ResolverURLSession.shared.session.configuration.httpCookieAcceptPolicy = .always
            ResolverURLSession.shared.session.configuration.httpShouldSetCookies = true

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw ProviderError.wrongURL
            }

            if data == nil {
                var cs = CharacterSet.urlQueryAllowed
                //                cs.remove("+")
                cs.remove("&")
                cs.insert("µ")
                cs.insert("%")

                components.queryItems = components.queryItems ?? []
                parameters.forEach { key, value in
                    components.queryItems?.append(URLQueryItem(name: key, value: value))
                }

                components.percentEncodedQuery = components.queryItems?.compactMap { item -> String? in
                    guard let value = item.value else { return nil }
                    return "\(item.name)=\(value)".addingPercentEncoding(withAllowedCharacters: cs)
                }.joined(separator: "&")

            }
            var stringURL = components.url?.absoluteString ?? ""
            if stringURL.last == "?" {
                stringURL.remove(at: stringURL.index(before: stringURL.endIndex))
            }
            guard let url = URL(string: stringURL) else {
                throw ProviderError.wrongURL
            }

            logger.info("[Resolver] Requesting URL: \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            request.httpBody = data
            request.timeoutInterval = 120
            request.setValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
            request.setValue("cors", forHTTPHeaderField: "sec-fetch-mode")
            request.setValue(url.absoluteString, forHTTPHeaderField: "referer")
            request.setValue("en-US,en;q=0.9,ar;q=0.8", forHTTPHeaderField: "accept-language")
            if data != nil {
                request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
                request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "accept")
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            } else {
                request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9", forHTTPHeaderField: "accept")

            }
            request.setValue(url.absoluteString, forHTTPHeaderField: "authority")
            extraHeaders.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)

            }

            if url.absoluteString.contains("easypanel.host") || url.absoluteString.contains("disable-ads") {
                if let userID = Self.userID {
                    request.setValue(userID, forHTTPHeaderField: "x-streamer-id")
                }
                if let appVersion = Self.appVersion {
                    request.setValue(appVersion, forHTTPHeaderField: "x-app-version")
                }
                request.setValue(streamerBEkey, forHTTPHeaderField: "x-streamer-be-key")
                if let device = Self.device {
                    request.setValue(device, forHTTPHeaderField: "x-device")
                }

            } else {
                request.setValue(Constants.userAgent, forHTTPHeaderField: "user-agent")
            }
            let (rdata, response)  = try await ResolverURLSession.shared.session.asyncData(for: request)

            if let url = response.url,
               let httpResponse = response as? HTTPURLResponse,
               let fields = httpResponse.allHeaderFields as? [String: String] {

                let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                for cookie in cookies {
                    var cookieProperties = [HTTPCookiePropertyKey: Any]()
                    cookieProperties[.name] = cookie.name
                    cookieProperties[.value] = cookie.value
                    cookieProperties[.domain] = cookie.domain
                    cookieProperties[.path] = cookie.path
                    cookieProperties[.version] = cookie.version
                    cookieProperties[.expires] = Date().addingTimeInterval(31536000)

                    let newCookie = HTTPCookie(properties: cookieProperties)
                    HTTPCookieStorage.shared.setCookie(newCookie!)
                }
            }

            if solveCaptcha, let content = String(data: rdata, encoding: .utf8),
               content.contains("<title>Just a moment...</title>") {
                return (try await requestCloudFlareCookies(url: url, method: httpMethod).data(using: .utf8)!, response)
//                return try await requestResponse(url: url,httpMethod: httpMethod, parameters: parameters, data: data,extraHeaders: extraHeaders,solveCaptcha: solveCaptcha)
            }

            logger.info("[Resolver] Finished requesting: \(url.absoluteString) successfully ")
            return (rdata, response)
        }

    public static func downloadPage(url: URL,
                                    httpMethod: String = "GET",
                                    parameters: [String: String] = [:],
                                    data: Data? = nil,
                                    encoding: String.Encoding = .utf8,
                                    extraHeaders: [String: String] = [:],
                                    solveCaptcha: Bool = true) async throws -> String {
        let data = try await requestData(url: url, httpMethod: httpMethod, parameters: parameters, data: data, extraHeaders: extraHeaders, solveCaptcha: solveCaptcha)
        guard let content = String(data: data, encoding: encoding) else {
            throw ProviderError.noContent
        }
        return content

    }

    static func requestCloudFlare(url: URL, method: String = "GET") async throws -> String {
        let data: Data?
        if method == "POST" {
            data =  """
        {
            "cmd": "request.post",
            "postData": "",
            "url": "\(url.absoluteString)",
            "maxTimeout": 60000
        }
        """.data(using: .utf8)
        } else {
            data =  """
        {
            "cmd": "request.get",
            "url": "\(url.absoluteString)",
            "maxTimeout": 60000
        }
        """.data(using: .utf8)

        }
        let content = try await Utilities.requestData(url: cloudFlareResolver, httpMethod: "POST", data: data)
        let response =  try JSONDecoder().decode(ProxyResponse.self, from: content)
        return response.solution.response

    }

    static func requestCloudFlareCookies(url: URL, method: String = "GET") async throws -> String {
        let data: Data?
        if method == "POST" {
            data =  """
        {
            "cmd": "request.post",
            "postData": "",
            "url": "\(url.absoluteString)",
            "maxTimeout": 600000,
        }
        """.data(using: .utf8)
        } else {
            data =  """
        {
            "cmd": "request.get",
            "url": "\(url.absoluteString)",
            "maxTimeout": 600000
        }
        """.data(using: .utf8)

        }
        let content = try await Utilities.requestData(url: cloudFlareResolver, httpMethod: "POST", data: data)
        let response =  try JSONDecoder().decode(ProxyResponse.self, from: content)

        Constants.userAgent = response.solution.userAgent
//        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        for cookie in response.solution.cookies {
            var cookieProperties = [HTTPCookiePropertyKey: Any]()
            cookieProperties[.domain] = cookie.domain
            if let expiry = cookie.expiry {
                cookieProperties[.expires] = Date(timeIntervalSince1970: expiry)
            }
            cookieProperties[.name] = cookie.name
            cookieProperties[.path] = cookie.path
            cookieProperties[.init(rawValue: "sameSitePolicy")] = cookie.sameSite
            cookieProperties[.secure] = cookie.secure
            cookieProperties[.value] = cookie.value
            cookieProperties[.init(rawValue: "HttpOnly")] = cookie.httpOnly
            print(cookie.name)
            print(cookie.value)
            if let newCookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(newCookie)
            }
        }

        return response.solution.response

    }

    static func getRedirect(url: URL) async throws -> URL {
        let (_, response) = try await Utilities.requestResponse(url: url)
        return response.url ?? url
    }

    // MARK: - Cooky
    struct Cooky: Codable, Equatable {
        let name, value, domain, path: String
        let expiry: Double?
        let httpOnly, secure: Bool
        let sameSite: String
    }

    private struct ProxyResponse: Equatable, Codable {
        var solution: Solution
    }

    // MARK: - Solution
    private struct Solution: Equatable, Codable {
        var response: String
        var userAgent: String
        let cookies: [Cooky]
    }

}
