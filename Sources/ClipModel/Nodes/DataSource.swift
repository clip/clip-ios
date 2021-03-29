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

import SwiftUI

@available(iOS 13.0, *)
public class DataSource: Layer {
    public enum HTTPMethod: String, Codable, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    public struct Header: Codable, Hashable {
        public var key: String
        public var value: String
        
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
    
    public let url: URL
    public let httpMethod: HTTPMethod
    public let httpBody: String?
    public let headers: [Header]
    public let schema: Schema
    
    public init(id: String = UUID().uuidString, name: String = "Data Source", parent: Node? = nil, children: [Node] = [], overrides: [String: Override], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Node? = nil, overlay: Node? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, url: URL, httpMethod: HTTPMethod = .get, httpBody: String? = nil, headers: [Header], schema: Schema) {
        self.url = url
        self.httpMethod = httpMethod
        self.httpBody = httpBody
        self.headers = headers
        self.schema = schema
        super.init(id: id, name: name, parent: parent, children: children, overrides: overrides, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility)
    }
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case url
        case httpMethod
        case httpBody
        case headers
        case schema
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        httpMethod = try container.decode(HTTPMethod.self, forKey: .httpMethod)
        httpBody = try container.decodeIfPresent(String.self, forKey: .httpBody)
        headers = try container.decode([Header].self, forKey: .headers)
        schema = try container.decode(Schema.self, forKey: .schema)
        try super.init(from: decoder)
    }
}
