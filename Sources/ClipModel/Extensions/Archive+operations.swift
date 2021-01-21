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
import ZIPFoundation

extension Archive {
    /// Extract the entire ZIP Entry (assuming it is a File entry) into a single buffer.
    func extractEntire(entry: Entry) throws -> Data {
        var buffer = Data(count: entry.uncompressedSize)
        var position = 0
        // despite the closure, this is not asynchronous.
        let _ = try self.extract(entry) { chunk in
            let endPos = Swift.min(position + chunk.count, entry.uncompressedSize)
            let targetRange: Range<Data.Index> = position..<endPos
            if targetRange.count > 0 {
                buffer[targetRange] = chunk
            }
            position = endPos
        }
        return buffer
    }

    func insertFiles(path: String, items: [String : Data], compressionMethod: CompressionMethod = .deflate) throws {
        try items.forEach { (name, data) in
            try self.addFile(path: NSString.path(withComponents: [path, name]), data: data, compressionMethod: compressionMethod)
        }
    }
    
    func addFile(path: String, data: Data, compressionMethod: CompressionMethod = .deflate) throws {
        let size = data.count
        try self.addEntry(
            with: path,
            type: Entry.EntryType.file,
            uncompressedSize: UInt32(size),
            modificationDate: Date(),
            compressionMethod: compressionMethod,
            bufferSize: defaultWriteChunkSize,
            progress: nil,
            provider: { (position, bufferSize) -> Data in
                let upperBound = Swift.min(size, position + bufferSize)
                let range = Range(uncheckedBounds: (lower: position, upper: upperBound))
                return data.subdata(in: range)
           }
        )
    }
}
