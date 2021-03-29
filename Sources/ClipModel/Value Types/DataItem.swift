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
public struct DataItem: Identifiable {
    public let id: String
    public let rawValue: [String: Any]

    public init(schema: Schema, jsonObject: [String: Any]) {
        if let idField = schema.first(where: { $0.type == .id }),
           let id = jsonObject[idField.key] as? String {
            self.id = id
        } else {
            id = UUID().uuidString
        }

        rawValue = schema.reduce(into: [:]) { result, dataField in
            let tokens = dataField.key.split(separator: ".").map { String($0) }
            let value = tokens.reduce(Optional<Any>.some(jsonObject)) { result, token in
                if let result = result as? [String: Any] {
                    return result[token]
                } else {
                    return nil
                }
            }

            switch dataField.type {
            case .id:
                result[dataField.key] = value.map { "\($0)" }
            case .number:
                result[dataField.key] = value as? Double
            case .text:
                result[dataField.key] = value as? String
            case .boolean:
                result[dataField.key] = value as? Bool
            case .url, .image:
                if let string = value as? String {
                    result[dataField.key] = URL(string: string)
                }
            case .color:
                // TODO: How are colours represented?
                break
            case .date:
                if var string = value as? String {
                    // Remove milliseconds
                    string = string.replacingOccurrences(
                        of: "\\.\\d+",
                        with: "",
                        options: .regularExpression
                    )
                    
                    result[dataField.key] = ISO8601DateFormatter().date(from: string)
                }
            case .collection:
                if let nestedSchema = dataField.nestedSchema,
                   let array = value as? [[String: Any]] {
                    result[dataField.key] = array.map {
                        DataItem(schema: nestedSchema, jsonObject: $0)
                    }
                }
            }
        }
    }

    public subscript(_ dataKey: String) -> Any? {
        get {
            rawValue[dataKey]
        }
    }
}
