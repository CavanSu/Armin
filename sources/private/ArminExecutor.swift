//
//  ArminExecutor.swift
//  Pods
//
//  Created by LYY on 2021/11/9.
//

import Foundation

extension Armin {
    func requestSuccess(of event: ArRequestEvent,
                        startTime: TimeInterval,
                        with url: String) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.armin(self,
                                 requestSuccess: event,
                                 startTime: startTime,
                                 url: url)
        }
    }
    
    func request(error: ArError,
                 of event: ArRequestEvent,
                 with url: String) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.armin(self,
                                 requestFail: error,
                                 event: event,
                                 url: url)
        }
    }
    
    static let defaultHTTPHeaders: [String : String] = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"
//        let acceptEncoding: String = ""

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        // Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 10.0.0) Alamofire/4.0.0`
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                    let osName: String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "OS X"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknown"
                        #endif
                    }()

                    return "\(osName) \(versionString)"
                }()

                let arminVersion: String = {
                    guard let arInfo = Bundle(for: Armin.self).infoDictionary,
                        let build = arInfo["CFBundleShortVersionString"]
                    else { return "Unknown" }

                    return "Armin/\(build)"
                }()

                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(arminVersion)"
            }

            return "Armin"
        }()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent
        ]
    }()
}


extension String {
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
    
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
}
}
