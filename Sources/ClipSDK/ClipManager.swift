// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of 
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import os.log
import UIKit
import BackgroundTasks
import ClipModel

public final class ClipManager {
    /// Access token.
    public let accessToken: String
    
    /// App domain name.
    public let domains: [String]
    
    /// Obtain the Clip SDK instance (after calling [initialize(accessToken:domain:)](x-source-tag://initialize)).
    public static var sharedInstance: ClipManager {
        get {
            guard let instance = _instance else {
                fatalError("Unexpected usage of Clip SDK API before Clip is initialized. Be sure to call `Clip.initialize()` prior to using Clip.")
            }
            return instance
        }
    }
    
    private static var _instance: ClipManager?

    /// Initialize the ClipSDK given the accessToken and domain name.
    /// - Tag: initialize
    public static func initialize(accessToken: String, domains: String...) {
        Self.initialize(accessToken: accessToken, domains: domains)
    }

    /// Initialize the ClipSDK given the accessToken and domain name.
    internal static func initialize(accessToken: String, domains: [String]) {
        precondition(!accessToken.isEmpty, "Missing Clip access token.")
        precondition(!domains.isEmpty, "Must have at least a single Clip domain.")
        precondition(!domains.contains(where: \.isEmpty), "Clip domains must not be empty strings.")
        _instance = ClipManager(accessToken: accessToken, domains: domains)
    }

    private init(accessToken: String, domains: [String]) {
        self.accessToken = accessToken
        self.domains = domains
    }
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case cannotLaunchClip(name: String)

        public var description: String {
            switch self {
                case .cannotLaunchClip(let name):
                    return "Can't launch Clip: \(name)"
            }
        }
    }

    @available(iOS 13.0, *)
    internal lazy var repository: ClipRepository = ClipRepository()
    
    @available(iOS 13.0, *)
    internal lazy var downloader: AssetsDownloader = AssetsDownloader(cache: assetsURLCache)

    static let userDefaults = UserDefaults(suiteName: "app.clip.ClipSDK")!

    // MARK: Configurable
    
    /// To customize Clip's caching behavior (such as the change the default limits on cache storage), replace this URLCache with a custom configured instance.
    public lazy var urlCache: URLCache = .clipDefaultCache()

    /// Downloaded assets cache.
    public lazy var assetsURLCache: URLCache = .clipAssetsDefaultCache()

    /// This NSCache is used to retain references to images loaded for display in Clips.  The images are not given calculated costs, so `totalCostLimit` should be in terms of total images, not bytes of memory.
    public lazy var imageCache: NSCache<NSURL, UIImage> = .clipDefaultImageCache()
    
    /// The libdispatch queue used for fetching and decoding images.
    public lazy var imageFetchAndDecodeQueue: DispatchQueue = DispatchQueue(label: "app.clip.ImageFetchAndDecode", attributes: .concurrent)
    
    /// To customize the Nav Bar View Controller, replace this function reference with a custom one that instantiates your own NavBarViewController subclass.
    @available(iOS 13.0, *)
    public lazy var navBarViewController: (_ document: Document, _ screen: Screen, _ navBarAppearance: NavBarAppearance?) -> NavBarViewController =
        NavBarViewController.init(document:screen:navBarAppearance:)
    
    /// To customize the Screen View Controller, replace this function reference with a custom one that instantiates your own ScreenViewController subclass.
    @available(iOS 13.0, *)
    public lazy var screenViewController: (_ document: Document, _ screen: Screen, _ navBarAppearance: NavBarAppearance?) -> ScreenViewController = ScreenViewController.init(document:screen:navBarAppearance:)
    
    // MARK: Methods

    /// Register push notifications token on a server.
    /// - Parameter apnsToken: A globally unique token that identifies this device to APNs.
    public func setPushToken(apnsToken deviceToken: Data) {
        let tokenStringHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        if #available(iOS 12.0, *) {
            clip_log(.debug, "Registering for Clip remote notifications with token: %@", tokenStringHex)
        }
        let requestBody = RegisterTokenBody(
            deviceID: UIDevice().identifierForVendor?.uuidString ?? "",
            deviceToken: tokenStringHex,
            environment: apsEnvironment
        )
        let jsonEncoder = JSONEncoder()
        let body: Data
        do {
            body = try jsonEncoder.encode(requestBody)
        } catch {
            clip_log(.error, "Unable to encode push token registration request message body")
            return
        }

        var request = URLRequest.clip(url: URL(string: "https://devices.clip.app/register")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { result in
            if case .failure(let error) = result {
                if #available(iOS 12.0, *) {
                    clip_log(.error, "Failed to register push token: %@", error.debugDescription)
                }
            }
        }.resume()
    }
    
    /// Call this method to instruct Clip to (asynchronously) perform a sync.
    /// - Parameters:
    ///   - prefetchAssets: Whether asynchronously prefetch assets found in synced Clips.
    ///   - completion: Completion handler.
    public func performSync(prefetchAssets: Bool = false, completion: (() -> Void)? = nil) {
        if #available(iOS 13.0, *) {
            repository.syncService.sync {
                if prefetchAssets {
                    self.prefetchAssets() {
                        completion?()
                    }
                } else {
                    completion?()
                }
            }
        } else {
            clip_log(.debug, "Clip runs in skeleton mode on iOS <13, ignoring sync request.")
        }
    }

    private let prefetchQueue = DispatchQueue(label: "app.clip.prefetch-assets")

    /// Asynchronously prefetch (download) assets found in account Clips
    /// - Parameter completion: Completion handler.
    
    public func prefetchAssets(completion: (() -> Void)? = nil) {
        // Gather image URLs from known (at least expected)
        // urls (Images) and enqueue to download with low priority
        
        guard #available(iOS 13.0, *) else {
            clip_log(.debug, "Clip runs in skeleton mode on iOS <13, ignoring asset prefetch request.")
            completion?()
            return
        }
        
        let group = DispatchGroup()
        
        group.enter()
        let documentURLs = repository.syncService.persistentFetchedDocumentURLs
        prefetchQueue.async {
            defer { group.leave() }
            
            return Set(
                documentURLs
                    .compactMap {
                        self.urlCache.cachedClip(url: $0)
                    }
                    .flatMap {
                        $0.nodes.flatten()
                    }
                    .flatMap { node -> [URL] in
                        switch node {
                        case let image as Image:
                            if image.inlineImage == nil && image.darkModeInlineImage == nil {
                                return [image.imageURL, image.darkModeImageURL].compactMap({ $0 })
                            } else {
                                return []
                            }
                        default:
                            return []
                        }
                    }
                    .filter {
                        self.assetsURLCache.cachedResponse(for: URLRequest(url: $0)) == nil
                    }
            ).forEach {
                group.enter()
                self.downloader.enqueue(url: $0, priority: .low) { _ in
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    /// Handle a background notification.
    /// - Parameters:
    ///   - userInfo: A dictionary that contains data from the notification payload.
    ///   - completionHandler: The block to execute after the operation completes.
    public func handleDidReceiveRemoteNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let clipDictionary = userInfo["clip"] as? [AnyHashable: Any], let action = clipDictionary["action"] as? String, action == "SYNC" else {
            completionHandler(.noData)
            return
        }

        performSync(prefetchAssets: true) {
            completionHandler(.newData)
        }
    }

    /// Register and schedule background refresh task.
    ///
    /// Register each task identifier only once. The system kills the app on the second registration of the same task identifier.
    /// - Parameter taskIdentifier: A unique string containing the identifier of the task.
    /// - Parameter timeInterval: The time interval after what run the task.
    public func registerAppRefreshTask(taskIdentifier: String, timeInterval: TimeInterval = 15 * 60) {
        precondition(!taskIdentifier.isEmpty, "Missing task identifier.")
        precondition(!accessToken.isEmpty, "Missing Clip access token.")
        precondition(!domains.isEmpty, "Must have at least a single Clip domain.")

        if #available(iOS 13.0, *) {
            AppRefreshTask.registerBackgroundTask(taskIdentifier: taskIdentifier, timeInterval: timeInterval, accessToken: accessToken, domains: domains)
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { (notification) in
                AppRefreshTask.scheduleClipRefresh(taskIdentifier: taskIdentifier, timeInterval: timeInterval)
            }
        } else {
            clip_log(.debug, "Clip runs in skeleton mode on iOS <13, ignoring background app refresh task registration request.")
        }
    }

    // MARK: Computed Values
    
    internal var domainURLs: [URL] {
        self.domains.map { domain in
            guard let url = URL(string: "https://\(domain)") else {
                fatalError("Invalid domain '\(domain)' given to Clip SDK.")
            }
            return url
        }
    }
    
    internal var apsEnvironment: String {
            #if targetEnvironment(simulator)
            return "SIMULATOR"
            #else
            guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
                clip_log(.error, "Provisioning profile not found")
                return "PRODUCTION"
            }
            
            guard let embeddedProfile = try? String(contentsOfFile: path, encoding: String.Encoding.ascii) else {
                clip_log(.error, "Failed to read provisioning profile at path: %@", path)
                return "PRODUCTION"
            }
            
            let scanner = Scanner(string: embeddedProfile)
            var string: NSString?
            
            guard scanner.scanUpTo("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", into: nil), scanner.scanUpTo("</plist>", into: &string) else {
                clip_log(.error, "Unrecognized provisioning profile structure")
                return "PRODUCTION"
            }
            
            guard let data = string?.appending("</plist>").data(using: String.Encoding.utf8) else {
                clip_log(.error, "Failed to decode provisioning profile")
                return "PRODUCTION"
            }
            
            guard let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] else {
                clip_log(.error, "Failed to serialize provisioning profile")
                return "PRODUCTION"
            }
            
            guard let entitlements = plist["Entitlements"] as? [String: Any], let apsEnvironment = entitlements["aps-environment"] as? String else {
                clip_log(.info, "No entry for \"aps-environment\" found in Entitlements – defaulting to production")
                return "PRODUCTION"
            }
            
            return apsEnvironment.uppercased()
            #endif
        }
}

private extension URLCache {
    static func clipDefaultCache() -> URLCache {
        let cacheURL = try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ClipCache", isDirectory: true)

        if #available(iOS 13.0, *) {
            return URLCache(memoryCapacity: 1_048_576 * 64, diskCapacity: 1_048_576 * 256, directory: cacheURL)
        } else {
            // the cache is entirely unused on earlier than iOS 13 since the SDK does not operate.
            return URLCache()
        }
    }

    static func clipAssetsDefaultCache() -> URLCache {
        let cacheURL = try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ClipAssetsCache", isDirectory: true)

        if #available(iOS 13.0, *) {
            return URLCache(memoryCapacity: 1_048_576 * 64, diskCapacity: 1_048_576 * 256, directory: cacheURL)
        } else {
            // the cache is entirely unused on earlier than iOS 13 since the SDK does not operate.
            return URLCache()
        }
    }
}

private extension NSCache {
    @objc static func clipDefaultImageCache() -> NSCache<NSURL, UIImage> {
        let c = NSCache<NSURL, UIImage>()
        c.totalCostLimit = 40
        c.name = "Clip Image Cache"
        return c
    }
}

private struct RegisterTokenBody: Codable {
    var deviceID: String
    var deviceToken: String
    var environment: String
}
