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
import SwiftUI
import CoreGraphics

@available(iOS 13.0, *)
public class Node: Decodable, Identifiable {
    /// A UUID for this node.
    public let id: String

    /// The name of the of the node.
    public let name: String?
    public private(set) var parent: Node?
    /// An array of node that are children of this node.
    public private(set) var children = [Node]()
    
    // Overrides
    public let overrides: [String: Override]
    
    // Layout
    public let ignoresSafeArea: Set<Edge>?
    public let aspectRatio: CGFloat?
    public let padding: Padding?
    public let frame: Frame?
    public let layoutPriority: CGFloat?
    public let offset: CGPoint?
    
    // Appearance
    public let shadow: Shadow?
    public let opacity: CGFloat?
    
    // Layering
    public let background: Node?
    public let overlay: Node?
    public let mask: Node?
    
    // Interaction
    public let action: Action?
    public let accessibility: Accessibility?
    
    public init(id: String = UUID().uuidString, name: String, parent: Node? = nil, children: [Node] = [], overrides: [String: Override], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Node? = nil, overlay: Node? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
        self.children = children
        self.overrides = overrides
        self.ignoresSafeArea = ignoresSafeArea
        self.aspectRatio = aspectRatio
        self.padding = padding
        self.frame = frame
        self.layoutPriority = layoutPriority
        self.offset = offset
        self.shadow = shadow
        self.opacity = opacity
        self.background = background
        self.overlay = overlay
        self.mask = mask
        self.action = action
        self.accessibility = accessibility
        
        self.children.forEach { $0.parent = self }
    }
    
    // MARK: Hierarchy

    func firstAncestor(where predicate: (Node) -> Bool) -> Node? {
        func firstMatchingAncestor(of node: Node) -> Node? {
            guard let parent = node.parent else {
                return nil
            }

            if predicate(parent) {
                return parent
            }

            return firstMatchingAncestor(of: parent)
        }

        return firstMatchingAncestor(of: self)
    }
    
    // MARK: Decodable

    static var typeName: String {
        String(describing: Self.self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
        case id
        case name
        case childIDs
        case isSelected
        case isCollapsed
        case overrides
        case ignoresSafeArea
        case aspectRatio
        case padding
        case frame
        case layoutPriority
        case offset
        case shadow
        case opacity
        case background
        case overlay
        case mask
        case action
        case accessibility
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Node.ID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
        
        // Overrides
        overrides = try container.decode([String: Override].self, forKey: .overrides)
        
        // Layout
        ignoresSafeArea = try container.decodeIfPresent(Set<Edge>.self, forKey: .ignoresSafeArea)
        aspectRatio = try container.decodeIfPresent(CGFloat.self, forKey: .aspectRatio)
        padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
        frame = try container.decodeIfPresent(Frame.self, forKey: .frame)
        layoutPriority = try container.decodeIfPresent(CGFloat.self, forKey: .layoutPriority)
        offset = try container.decodeIfPresent(CGPoint.self, forKey: .offset)
        
        // Appearance
        shadow = try container.decodeIfPresent(Shadow.self, forKey: .shadow)
        opacity = try container.decodeIfPresent(CGFloat.self, forKey: .opacity)
        
        // Layering
        background = try container.decodeIfPresent(AnyNode.self, forKey: .background)?.node
        overlay = try container.decodeIfPresent(AnyNode.self, forKey: .overlay)?.node
        mask = try container.decodeIfPresent(AnyNode.self, forKey: .mask)?.node
        
        // Interaction
        action = try container.decodeIfPresent(Action.self, forKey: .action)
        accessibility = try container.decodeIfPresent(Accessibility.self, forKey: .accessibility)

        if container.contains(.childIDs) {
            coordinator.registerOneToManyRelationship(
                nodeIDs: try container.decode([Node.ID].self, forKey: .childIDs),
                to: self,
                keyPath: \.children,
                inverseKeyPath: \.parent
            )
        }
    }
}

// MARK: Sequence

@available(iOS 13.0, *)
extension Sequence where Element: Node {
    
    #if os(macOS)
    /// Returns a collection of nodes which have the given traits.
    func filter(_ traits: Traits) -> [Element] {
        filter { $0.traits.contains(traits) }
    }
    #endif
    
    /// Traverses the node graph, starting with the node's children, until it finds a node that matches the
    /// supplied predicate, from the top of the z-order.
    func highest(where predicate: (Node) -> Bool) -> Node? {
        reduce(nil) { result, node in
            guard result == nil else {
                return result
            }
            
            if predicate(node) {
                return node
            }
            
            return node.children.highest(where: predicate)
        }
    }
    
    /// Traverses the node graph, starting with the node's children, until it finds a node that matches the
    /// supplied predicate, from the bottom of the z-order.
    func lowest(where predicate: (Node) -> Bool) -> Node? {
        reversed().reduce(nil) { result, node in
            guard result == nil else {
                return result
            }
            
            if predicate(node) {
                return node
            }
            
            return node.children.lowest(where: predicate)
        }
    }
    
    func traverse(_ block: (Node) -> Void) {
        forEach { node in
            block(node)
            node.children.traverse(block)
        }
    }

    func flatten() -> [Node] {
        flatMap { node -> [Node] in
            [node] + node.children.flatten()
        }
    }
}

