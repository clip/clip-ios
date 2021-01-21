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
import ClipModel
import os.log

@available(iOS 13.0, *)
final public class ClipRepository {

    enum Error: Swift.Error {
        case notAvailable
    }

    /// Data synchronization service
    let syncService = SyncService()
    
    /// Retrieve Clip document data
    /// - Parameter url: Clip URL
    public func retrieveClip(url: URL, ignoreCache: Bool = false, completion: @escaping (Result<Document, Swift.Error>) -> Void) {
        guard let host = NSURLComponents(url: url, resolvingAgainstBaseURL: true)?.host, ClipManager.sharedInstance.domains.contains(host) else {
            let host = NSURLComponents(url: url, resolvingAgainstBaseURL: true)?.host ?? "<unknown>"
            clip_log(.error, "Attempt to retrieve a Clip for a domain not configured with ClipManager.initialize(): %@", host)
            DispatchQueue.main.async {
                completion(Result.failure(UnsupportedDomainError(domain: host)))
            }
            return
        }
        
        
        syncService.fetchDocumentData(url: url, cachePolicy: ignoreCache ? .reloadIgnoringLocalAndRemoteCacheData : .returnCacheDataElseLoad) { result in
            do {
                let documentData = try result.get()
                let document = try Document(decode: documentData)
                DispatchQueue.main.async {
                    completion(.success(document))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

struct UnsupportedDomainError: Error, LocalizedError {
    var domain: String
    
    var errorDescription: String? {
        "Unsupported Clip domain: \(domain)"
    }
}
