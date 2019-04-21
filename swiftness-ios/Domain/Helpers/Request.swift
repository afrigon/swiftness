//
//    MIT License
//
//    Copyright (c) 2019 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import Foundation

fileprivate extension URLRequest {
    var headers: RequestHeaders {
        get { return RequestHeaders(self.allHTTPHeaderFields ?? [:]) }
        set { self.allHTTPHeaderFields = newValue.headers }
    }

    mutating func addHeader(_ header: RequestHeader) {
        self.addValue(header.value, forHTTPHeaderField: header.name)
    }

    var method: HTTPMethod {
        get { return HTTPMethod(rawValue: self.httpMethod ?? "GET") ?? .get }
        set { self.httpMethod = newValue.rawValue }
    }
}

fileprivate extension Collection where Element == String {
    var qualityEncoded: String {
        return self.enumerated().map { "\($1);q=\(1.0 - (Double($0) * 0.1))" }.joined(separator: ", ")
    }
}

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"

    init(_ method: String?) {
        self = HTTPMethod(rawValue: (method ?? "GET").uppercased()) ?? .get
    }

    public func `in`(_ methods: [HTTPMethod]) -> Bool {
        return methods.contains(self)
    }
}

public enum HTTPStatusCode: Int {
    case
    `continue` = 100,
    switchingProtocols = 101,

    ok = 200,
    created = 201,
    accepted = 202,
    nonAuthoritativeInformation = 203,
    noContent = 204,
    resetContent = 205,
    partialContent = 206,

    multipleChoices = 300,
    movedPermanently = 301,
    found = 302,
    seeOther = 303,
    notModified = 304,
    useProxy = 305,
    unused = 306,
    temporaryRedirect = 307,

    badRequest = 400,
    unauthorized = 401,
    paymentRequired = 402,
    forbidden = 403,
    notFound = 404,
    methodNotAllowed = 405,
    notAcceptable = 406,
    proxyAuthenticationRequired = 407,
    requestTimeout = 408,
    conflict = 409,
    gone = 410,
    lengthRequired = 411,
    preconditionFailed = 412,
    requestEntityTooLarge = 413,
    requestUriTooLong = 414,
    unsupportedMediaType = 415,
    requestedRangeNotSatisfiable = 416,
    expectationFailed = 417,
    isTeapot = 418,
    tooManyRequest = 429,

    internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505,

    // Customs
    unknown = 1000,
    invalidUrl = 1001,
    invalidUrlRequest = 1002,
    invalidUrlResponse = 1003,
    invalidData = 1004,
    urlSessionError = 1005,
    jsonParsingError = 1006,
    objectParsingError = 1007,
    imageParsingError = 1008,
    invalidResponseMimeType = 1009

    public var string: String {
        let s = String(describing: self)
        return try! NSRegularExpression(pattern: "([A-Z])").stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: " $0")
    }

    init(_ statusCode: Int = 1000) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .unknown
    }
}

public enum RequestStatus {
    case pending, running, completed, errored, cancelled

    public func `in`(_ statuses: [RequestStatus]) -> Bool {
        return statuses.contains(self)
    }
}

public enum RequestLogLevel: UInt8 {
    case none = 0, error = 1, warning = 2, info = 3, debug = 4
}

fileprivate class RequestLogger {
    static func log(_ requiredLevel: RequestLogLevel, _ s: String) {
        guard Request.logLevel.rawValue >= requiredLevel.rawValue else { return }

        let logString = String(describing: requiredLevel).uppercased()
        print("(FrigKit-Request) \(logString): \(s)")
    }
}

fileprivate struct RequestValidation {
    let range: Range<Int>?
    let mimeType: String?

    func validate(response: HTTPURLResponse) -> RequestError? {
        if let range = self.range {
            guard range.contains(response.statusCode) else {
                return RequestError(statusCode: HTTPStatusCode(response.statusCode))
            }
        }

        if let mimeType = self.mimeType, let responseMimeType = response.mimeType {
            guard mimeType == responseMimeType else {
                return RequestError(statusCode: .invalidResponseMimeType)
            }
        }

        return nil
    }
}

public struct RequestError: CustomStringConvertible {
    public let url: String?
    public let method: String?
    public let statusCode: HTTPStatusCode

    public var description: String {
        if let url = self.url, let method = self.method {
            return "\(method) (\(url)): \(self.statusCode.rawValue) \(self.statusCode.string)"
        }

        return "\(self.statusCode.rawValue) \(self.statusCode.string)"
    }

    init(url: URL? = nil, method: HTTPMethod? = nil, statusCode: HTTPStatusCode = HTTPStatusCode()) {
        self.url = url != nil ? url!.absoluteString : nil
        self.method = method?.rawValue ?? nil
        self.statusCode = statusCode
    }
}

public class RequestHeaders {
    fileprivate var headers = [String: String]()

    init() {
        if Request.useDefaultHeaders { self.addDefaultHeaders() }
    }

    convenience init(_ headers: [String: String]) {
        self.init()
        for (key, value) in headers {
            self.headers[key] = value
        }
    }

    convenience init(_ headers: [RequestHeader]) {
        self.init()
        for header in headers {
            self.headers[header.name] = header.value
        }
    }

    subscript(name: String) -> String? {
        get { return self.headers[name] }
        set { self.headers[name] = newValue }
    }

    public func add(_ header: RequestHeader) {
        self.headers[header.name] = header.value
    }

    public func add(name: String, value: String) {
        self.headers[name] = value
    }

    private func addDefaultHeaders() {
        self.add(RequestHeader.defaultAcceptEncoding)
        self.add(RequestHeader.defaultAcceptLanguage)
        self.add(RequestHeader.defaultUserAgent)
    }
}

public class RequestHeader: CustomStringConvertible {
    public var name: String
    public var value: String

    public var description: String {
        return "\(self.name): \(self.value)"
    }

    init (name: String, value: String) {
        self.name = name
        self.value = value
    }

    public static let defaultAcceptEncoding: RequestHeader = {
        var encodings = ["gzip", "deflate"]
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) { encodings.insert("br", at: 0) }
        return RequestHeader.acceptEncoding(encodings.qualityEncoded)
    }()

    public static let defaultAcceptLanguage: RequestHeader = {
        RequestHeader.acceptLanguage(Locale.preferredLanguages.prefix(6).qualityEncoded)
    }()

    public static let defaultUserAgent: RequestHeader = {
        guard let info = Bundle.main.infoDictionary else {
            return RequestHeader.userAgent("FrigKit")
        }

        let appName = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
        let appVersion = info["CFBundleShortVersionString"] as? String ?? "0.0"
        let appBundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
        let appBuild = info[kCFBundleVersionKey as String] as? String ?? "-1"
        let osName: String = {
            #if os(iOS)
            return "iOS"
            #elseif os(watchOS)
            return "watchOS"
            #elseif os(macOS)
            return "macOS"
            #elseif os(tvOS)
            return "tvOS"
            #elseif os(Linux)
            return "Linux"
            #else
            return "Unknown"
            #endif
        }()
        let osInfo = ProcessInfo.processInfo.operatingSystemVersion
        let osTag = "\(osName) \(osInfo.majorVersion).\(osInfo.minorVersion).\(osInfo.patchVersion)"
        let frigKitTag = "FrigKit/\(Bundle(for: Request.self).infoDictionary?["CFBundleShortVersionString"] ?? "0.0")"

        return RequestHeader.userAgent("\(appName)/\(appVersion) (\(appBundle); build:\(appBuild); \(osTag)) \(frigKitTag)")
    }()

    public static func authorization(_ value: String) -> RequestHeader {
        return RequestHeader(name: "Authorization", value: value)
    }

    public static func authorization(username: String, password: String) -> RequestHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return RequestHeader.authorization("Basic \(credential)")
    }

    public static func authorization(token: String) -> RequestHeader {
        return RequestHeader.authorization("Bearer \(token)")
    }

    public static func acceptEncoding(_ value: String) -> RequestHeader {
        return RequestHeader(name: "Accept-Encoding", value: value)
    }

    public static func acceptLanguage(_ value: String) -> RequestHeader {
        return RequestHeader(name: "Accept-Language", value: value)
    }

    public static func contentDisposition(_ value: String) -> RequestHeader {
        return RequestHeader(name: "Content-Disposition", value: value)
    }

    public static func contentType(_ value: String) -> RequestHeader {
        return RequestHeader(name: "Content-Type", value: value)
    }

    public static func contentLength(_ value: Int) -> RequestHeader {
        return RequestHeader(name: "Content-Length", value: String(value))
    }

    public static func userAgent(_ value: String) -> RequestHeader {
        return RequestHeader(name: "User-Agent", value: value)
    }
}

fileprivate protocol RequestResponse {
    func parse(data: Data?, error: RequestError?)
}

public class RawResponse: RequestResponse {
    fileprivate var _statusCode: Int?
    public var statusCode: Int { return self._statusCode ?? 1000 }

    fileprivate var _headers: [String: String]?
    public var headers: [String: String] { return self._headers ?? [:] }

    fileprivate var _error: RequestError?
    public var error: RequestError? { return self._error }

    private var _rawData: Data?
    public var rawData: Data? { return self._rawData }

    fileprivate func parse(data: Data?, error: RequestError?) {
        self._rawData = data
        self._error = error
    }
}

public class TextResponse: RawResponse {
    private var _text: String?
    public var text: String? { return self._text }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            self._text = String(data: data, encoding: .utf8)
        }

        super.parse(data: data, error: error)
    }
}

public class JSONResponse: RawResponse {
    private var _isArray: Bool = false
    public var isArray: Bool { return self._isArray }

    private var _json: Any?
    public var json: Any { return self._json as Any }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            do {
                self._json = try JSONSerialization.jsonObject(with: data)

                if self._json as? [[String: Any]] != nil {
                    self._isArray = true
                }
            } catch {
                self._error = RequestError(statusCode: .jsonParsingError)
            }
        }

        super.parse(data: data, error: error)
    }
}

public class ObjectResponse<T: Decodable>: JSONResponse {
    private var _object: T?
    public var object: T? { return self._object }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            do {
                self._object = try JSONDecoder().decode(T.self, from: data)
            } catch {
                self._error = RequestError(statusCode: .objectParsingError)
            }
        }

        super.parse(data: data, error: error)
    }
}

public class Request {
    public static var logLevel: RequestLogLevel = .warning
    public static var autoValidate: Bool = true
    public static var useDefaultHeaders: Bool = true

    private let requestId: String = NSUUID().uuidString

    private var _status: RequestStatus = .pending
    public var status: RequestStatus { return self._status }

    private var _error: RequestError?
    public var error: RequestError? { return self._error }

    private var validation: RequestValidation?

    var urlRequest: URLRequest?
    fileprivate var response: RawResponse?
    fileprivate var task: URLSessionTask?

    public var cachePolicy: URLRequest.CachePolicy {
        get { return self.urlRequest?.cachePolicy ?? .reloadRevalidatingCacheData }
        set { self.urlRequest?.cachePolicy = newValue }
    }

    public var timeoutInterval: TimeInterval {
        get { return self.urlRequest?.timeoutInterval ?? 0 }
        set { self.urlRequest?.timeoutInterval = newValue }
    }

    convenience init(_ url: String, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: RequestHeaders = RequestHeaders()) {
        self.init(URL(string: url), method: method, parameters: parameters, headers: headers)
    }

    init(request: URLRequest) {
        RequestLogger.log(.debug, "creating (\(self.requestId)) from URLRequest object")

        let method: HTTPMethod = HTTPMethod(request.httpMethod)
        guard let url = request.url else {
            self.set(error: RequestError(method: method, statusCode: .invalidUrl))
            return
        }

        self.urlRequest = request
        self.urlRequest!.method = method

        if Request.autoValidate { self.validate() }

        RequestLogger.log(.debug, "\(method.rawValue) \(url)")
    }

    init(_ url: URL?, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: RequestHeaders = RequestHeaders()) {
        RequestLogger.log(.debug, "creating (\(self.requestId)) from arguments")

        guard let url = url else {
            self.set(error: RequestError(method: method, statusCode: .invalidUrl))
            return
        }

        self.urlRequest = URLRequest(url: url)
        self.urlRequest?.headers = headers
        self.urlRequest!.method = method
        self.urlRequest!.cachePolicy = .reloadRevalidatingCacheData

        if Request.autoValidate { self.validate() }

        RequestLogger.log(.debug, "\(method.rawValue) \(url)")
    }

    public static func == (_ lhs: Request, _ rhs: Request) -> Bool { return lhs.requestId == rhs.requestId }
    public static func != (_ lhs: Request, _ rhs: Request) -> Bool { return (lhs == rhs) }

    private func set(error: RequestError) {
        self._error = error
        self._status = .errored
        RequestLogger.log(.error, "\(error.description)")
    }

    @discardableResult
    public func validate(range: Range<Int>? = nil, mimeType: String? = nil) -> Request {
        if self.validation == nil {
            RequestLogger.log(.debug, "turning on validation module")
        }

        if range == nil && mimeType == nil {
            self.validation = RequestValidation(range: 200..<300, mimeType: mimeType)
        } else {
            self.validation = RequestValidation(range: range, mimeType: mimeType)
        }


        if let mimeType = mimeType {
            RequestLogger.log(.debug, "using \(mimeType) as validation mime type")
        }

        if let range = self.validation!.range {
            RequestLogger.log(.debug, "using \(range) as validation range")
        }

        return self
    }

    @discardableResult
    public func addHeader(_ header: RequestHeader) -> Request {
        self.urlRequest?.addHeader(header)
        return self
    }

    public func cancel() {
        RequestLogger.log(.info, "cancelling (\(self.requestId))")
        guard !self.status.in([.cancelled, .completed, .errored]) else { return }

        self._status = .cancelled
        self.task?.cancel()

        RequestLogger.log(.info, "cancelled query to \(self.urlRequest!.method.rawValue) \(self.urlRequest!.url?.absoluteString ?? "nil")")
    }

    private func resume(callback: @escaping () -> Void) {
        RequestLogger.log(.debug, "sending (\(self.requestId))")

        guard self.urlRequest != nil else {
            self.set(error: RequestError(statusCode: .invalidUrlRequest))
            return callback()
        }

        guard !self.status.in([.running, .cancelled]) else {
            RequestLogger.log(.warning, "stoped sending (\(self.requestId)) because its status was \(self._status)")
            return callback()
        }
        self._status = .running

        RequestLogger.log(.info, "\(self.urlRequest!.method.rawValue) \(self.urlRequest!.url?.absoluteString ?? "nil")")

        self.task = URLSession.shared.dataTask(with: self.urlRequest!) { (data, response, error) in
            RequestLogger.log(.debug, "response from (\(self.requestId))")

            if error != nil {
                self.set(error: RequestError(url: self.urlRequest!.url, method: self.urlRequest!.method, statusCode: .urlSessionError))
                self.response!.parse(data: data, error: self._error)
                return DispatchQueue.main.async { return callback() }
            }

            if let response = response as? HTTPURLResponse {
                self.response!._statusCode = response.statusCode
                self.response!._headers = response.allHeaderFields as? [String: String]

                if let error = self.validation?.validate(response: response) {
                    self.set(error: error)
                    self.response?.parse(data: data, error: self._error)
                }
            }

            guard let data = data else {
                self.set(error: RequestError(url: self.urlRequest!.url, method: self.urlRequest!.method, statusCode: .invalidData))
                self.response!.parse(data: nil, error: self._error)
                return DispatchQueue.main.async { return callback() }
            }

            RequestLogger.log(.debug, "parsing (\(self.requestId))")

            self.response!.parse(data: data, error: self._error)
            self._status = .completed
            DispatchQueue.main.async { return callback() }
        }

        self.task!.resume()
    }

    func send(callback: ((RawResponse) -> Void)? = nil) {
        if let callback = callback {
            self.raw(callback: callback)
        } else {
            self.response = RawResponse()
            self.resume {}
        }
    }

    func raw(callback: @escaping (RawResponse) -> Void) {
        self.response = RawResponse()
        self.resume { callback(self.response!) }
    }

    func text(callback: @escaping (TextResponse) -> Void) {
        self.response = TextResponse()
        self.resume { callback(self.response as! TextResponse) }
    }

    func json(callback: @escaping (JSONResponse) -> Void) {
        self.response = JSONResponse()
        self.resume { callback(self.response as! JSONResponse) }
    }

    func object<T>(callback: @escaping (ObjectResponse<T>) -> Void) {
        self.response = ObjectResponse<T>()
        self.resume { callback(self.response as! ObjectResponse<T>) }
    }
}

extension Request {
    public func params(_ params: [String: Any]) -> Request {
        if self.urlRequest!.method.in([.get, .options, .trace]) {
            self.encodeQueryUrl(params: params)
            return self
        }

        self.encodeBodyUrl(params: params)
        return self
    }

    private func encodeQueryUrl(params: [String: Any]) {
        guard let url = self.urlRequest?.url else { return }

        let query = params.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        self.urlRequest?.url = URL(string: "\(url)\(url.query == nil ? "?" : "&")\(query)")
    }

    private func encodeBodyUrl(params: [String: Any]) {
        let body = params.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        self.urlRequest?.httpBody = body.data(using: .utf8)

        self.urlRequest?.addHeader(RequestHeader.contentType("application/x-www-form-urlencoded"))
    }

    public func params(json: Any) -> Request {
        do {
            self.urlRequest?.httpBody = try JSONSerialization.data(withJSONObject: json)
            self.urlRequest?.addHeader(RequestHeader.contentType("application/json"))
        } catch {
            self.set(error: RequestError(statusCode: .jsonParsingError))
        }

        return self
    }

    public func params<T: Encodable>(object: T) -> Request {
        do {
            self.urlRequest?.httpBody = try JSONEncoder().encode(object)
            self.urlRequest?.addHeader(RequestHeader.contentType("application/json"))
        } catch {
            self.set(error: RequestError(statusCode: .jsonParsingError))
        }

        return self
    }

    public func params(multipart params: [String: Any]) -> Request {
        let boundary = "Frigkit+\(arc4random())\(arc4random())"
        let formData = MultipartData(boundary: boundary)

        params.forEach { formData.append(name: $0.0, value: "\($0.1)".data(using: .utf8)!) }
        self.urlRequest?.httpBody = formData.toData()

        self.addHeader(RequestHeader.contentType("multipart/form-data; boundary=\(boundary)"))
        self.addHeader(RequestHeader.contentLength(self.urlRequest?.httpBody?.count ?? 0))

        return self
    }

    public func params(multipart formData: MultipartData) -> Request {
        let boundary = "Frigkit+\(arc4random())\(arc4random())"
        self.urlRequest?.httpBody = formData.toData()

        self.addHeader(RequestHeader.contentType("multipart/form-data; boundary=\(boundary)"))
        self.addHeader(RequestHeader.contentLength(self.urlRequest?.httpBody?.count ?? 0))

        return self
    }

    public func upload(name: String, data: Data, filename: String? = nil, contentType: String = "application/octet-stream") -> Request {
        let boundary = "Frigkit+\(arc4random())\(arc4random())"
        let formData = MultipartData(boundary: boundary)
        formData.append(name: name, value: data, filename: filename, filetype: contentType)
        self.urlRequest?.httpBody = formData.toData()

        self.addHeader(RequestHeader.contentType("multipart/form-data; boundary=\(boundary)"))
        self.addHeader(RequestHeader.contentLength(self.urlRequest?.httpBody?.count ?? 0))

        return self
    }
}

public class MultipartData {
    private let crlf = "\r\n"
    private let boundary: String
    private var isFinal: Bool = false

    private let data = NSMutableData()

    init(boundary: String) {
        self.boundary = boundary
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func append(name: String, value: Data, filename: String? = nil, filetype: String? = nil) {
        guard !self.isFinal else { return }

        var string = "--\(boundary)\(crlf)"
        string += "Content-Disposition: form-data; name=\"\(name)\""
        if let filename = filename { string += "; filename=\"\(filename)\"" }
        string += crlf
        if let filetype = filetype { string += "Content-Type: \(filetype)\(crlf)" }
        string += crlf

        self.data.append(string.data(using: .utf8)!)
        self.data.append(value)
        self.data.append(crlf.data(using: .utf8)!)
    }

    public func toData() -> Data {
        if !self.isFinal {
            self.data.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
            self.isFinal = true
        }

        return self.data as Data
    }
}
