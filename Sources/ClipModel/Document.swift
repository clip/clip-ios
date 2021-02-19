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

@available(iOS 13.0, *)
public struct Document: Decodable {

    /// A unique identifier for the clip.
    public let id: Int
    /// The revision id of this clip. When a new version of the same Clip is uploaded the revision ID changes.
    public let clipRevisionID: Int
    /// A set of nodes contained in the document. Use `initialScreenID` to determine the initial node to render.
    public let nodes: [Node]
    public let localization: StringTable
    /// Fonts download URLs
    public let fonts: [URL]
    /// The ID of the initial node to render.
    public let initialScreenID: Screen.ID

    public init(id: Int, clipRevisionID: Int, nodes: [Node], localization: StringTable, fonts: [URL], initialScreenID: Screen.ID) {
        self.id = id
        self.clipRevisionID = clipRevisionID
        self.nodes = nodes
        self.initialScreenID = initialScreenID
        self.localization = localization
        self.fonts = fonts
    }

    /// Initialize Document from document data (JSON)
    /// - Parameter data: Document data.
    /// - Throws: Throws error on failure.
    public init(decode data: Data) throws {
        let decoder = JSONDecoder()
        let coordinator = DecodingCoordinator()
        decoder.userInfo[.decodingCoordinator] = coordinator
        self = try decoder.decode(Self.self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case clipRevisionID
        case nodes
        case fonts
        case initialScreenID
        case localization
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(Int.self, forKey: .id)
        let clipRevisionID = try container.decode(Int.self, forKey: .clipRevisionID)
        let initialScreenID = try container.decode(String.self, forKey: .initialScreenID)
        let localization = try container.decode(StringTable.self, forKey: .localization)
        let fonts = try container.decode([FontResource].self, forKey: .fonts)

        let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator

        let nodes = try container.decode([AnyNode].self, forKey: .nodes).map(\.node)
        coordinator.resolveRelationships(nodes: nodes)

        let fontURLs = fonts.map { $0.url }
        self.init(id: id, clipRevisionID: clipRevisionID, nodes: nodes, localization: localization, fonts: fontURLs, initialScreenID: initialScreenID)
    }
}
