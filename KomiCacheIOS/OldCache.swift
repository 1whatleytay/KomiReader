import Foundation
import SwiftUI

let cacheMagic = 0x6b6f6d6973616e77

func encodeSize(_ size: Int) -> Data {
    Data(withUnsafeBytes(of: Int64(size).bigEndian, Array.init) as [UInt8])
}

func decodeSize(_ data: Data) -> Int {
    Int(data.withUnsafeBytes({ ptr -> Int64 in ptr.load(as: Int64.self).bigEndian }))
}

func decodeSize(_ file: FileHandle) -> Int? {
    guard let data = try? file.read(upToCount: 8) else { return nil }
    
    if data.count < 8 {
        return nil
    }
    
    return decodeSize(data)
}

func decodeSize(_ stream: InputStream) -> Int {
    let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    
    let amount = stream.read(pointer, maxLength: 8)
    assert(amount == 8)
    
    var data = Data()
    data.append(pointer, count: 8)
    // probably could get a pointer to data
    
    pointer.deallocate()
    
    return decodeSize(data)
}

func encodeImages(data: [String: [Data]]) -> (data: Data, offsets: [String: Int]) {
    var result = Data()
    var offsets = [String: Int]()
    
    for (link, images) in data {
        var subdata = Data()
        
        for image in images {
            subdata.append(encodeSize(image.count))
            subdata.append(image)
        }
        
        offsets[link] = result.count
        
        result.append(encodeSize(images.count))
        result.append(subdata)
    }
    
    return (data: result, offsets: offsets)
}

func encodeHashTable(offsets: [String: Int]) -> (table: Data, elements: Data) {
    let bucketCount = offsets.count * 2
    
    var pointers = [Int](repeating: -1, count: bucketCount)
    
    var elements = Data()
    
    for (link, offset) in offsets {
        guard let textData = link.data(using: .utf8) else { continue }
        
        let initialPosition = link.hash % bucketCount
        let position = initialPosition >= 0 ? initialPosition : bucketCount + initialPosition
        
        let next = pointers[position] < 0 ? -1 : pointers[position]
        pointers[position] = elements.count
        
        elements.append(encodeSize(next))
        elements.append(encodeSize(offset))
        elements.append(encodeSize(textData.count))
        elements.append(textData)
    }
    
    var table = Data()
    
    table.append(encodeSize(bucketCount))
    
    for pointer in pointers {
        table.append(encodeSize(pointer))
    }
    
    return (table: table, elements: elements)
}

func encodeChapters(chapters: [Chapter]) -> Data {
    var result = Data()
    
    result.append(encodeSize(chapters.count))
    
    for chapter in chapters {
        result.append(encodeSize(chapter.chapter))
        
        if let nameText = chapter.name.data(using: .utf8) {
            result.append(encodeSize(nameText.count))
            result.append(nameText)
        } else {
            result.append(encodeSize(0))
        }
        
        if let linkText = chapter.link.data(using: .utf8) {
            result.append(encodeSize(linkText.count))
            result.append(linkText)
        } else {
            result.append(encodeSize(0))
        }
    }
    
    return result
}

func encodeCache(chapters: [Chapter], images: [String: [Data]]) -> Data {
    let (imageData, offsets) = encodeImages(data: images)
    let (tableData, elementsData) = encodeHashTable(offsets: offsets)
    let chaptersData = encodeChapters(chapters: chapters)
    
    var result = Data()
    
    result.append(encodeSize(cacheMagic))
    
    let magicSize = 8
    let offsetsSize = 8 * 4 // 4 * Int64
    
    let chaptersOffset = magicSize + offsetsSize
    let tableOffset = chaptersOffset + chaptersData.count
    let elementsOffset = tableOffset + tableData.count
    let imageOffset = elementsOffset + elementsData.count
    
    result.append(encodeSize(chaptersOffset))
    result.append(encodeSize(tableOffset))
    result.append(encodeSize(elementsOffset))
    result.append(encodeSize(imageOffset))
    
    assert(chaptersOffset == result.count)
    result.append(chaptersData)
    
    assert(tableOffset == result.count)
    result.append(tableData)
    
    assert(elementsOffset == result.count)
    result.append(elementsData)
    
    assert(imageOffset == result.count)
    result.append(imageData)
    
    return result
}

struct CacheOffsets {
    let chaptersOffset: Int
    let tableOffset: Int
    let elementsOffset: Int
    let imagesOffset: Int
}

func decodeCacheHeader(file: FileHandle) -> CacheOffsets? {
    try? file.seek(toOffset: 0)
    
    guard let data = try? file.read(upToCount: 40) else { return nil }
    
    if data.count < 40 {
        return nil
    }

    let magic = decodeSize(data.subdata(in: 0 ..< 8))

    if magic != cacheMagic {
        return nil
    }

    return CacheOffsets(
        chaptersOffset: Int(decodeSize(data.subdata(in: 8 ..< 16))),
        tableOffset: Int(decodeSize(data.subdata(in: 16 ..< 24))),
        elementsOffset: Int(decodeSize(data.subdata(in: 24 ..< 32))),
        imagesOffset: Int(decodeSize(data.subdata(in: 32 ..< 40)))
    )
}

func decodeChapters(chaptersOffset: Int, file: FileHandle) -> [Chapter]? {
    try? file.seek(toOffset: UInt64(chaptersOffset))
    
    guard let numChapters = decodeSize(file) else { return nil }
    
    var chapters = [Chapter]()
    chapters.reserveCapacity(numChapters)

    for _ in 0 ..< numChapters {
        guard let number = decodeSize(file) else { continue }

        guard let textSize = decodeSize(file) else { continue }
        guard let textData = try? file.read(upToCount: textSize) else { continue }
        guard let name = String(data: textData, encoding: .utf8) else { continue }

        guard let linkSize = decodeSize(file) else { continue }
        guard let linkData = try? file.read(upToCount: linkSize) else { continue }
        guard let link = String(data: linkData, encoding: .utf8) else { continue }

        chapters.append(Chapter(
            link: link,
            name: name,

            chapter: number
        ))
    }

    return chapters
}

func decodeHashTable(hashTableOffset: Int, file: FileHandle) -> [Int]? {
    try? file.seek(toOffset: UInt64(hashTableOffset))
    
    guard let length = decodeSize(file) else { return nil }
    
    var indices = [Int]()
    indices.reserveCapacity(length)
    
    for _ in 0 ..< length {
        guard let element = decodeSize(file) else { return nil }
        indices.append(element)
    }
    
    return indices
}

func indexHashTable(elementsOffset: Int, file: FileHandle, indices: [Int], link: String) -> Int? {
    let hash = link.hash
    
    let initialPosition = hash % indices.count
    let position = initialPosition >= 0 ? initialPosition : indices.count + initialPosition
    
    var nextOffset = indices[position]
    
    while (nextOffset >= 0) {
        try? file.seek(toOffset: UInt64(elementsOffset + nextOffset))
        
        guard let next = decodeSize(file) else { return nil }
        guard let imagesOffset = decodeSize(file) else { return nil }
        
        guard let textLength = decodeSize(file) else { return nil }
        guard let textData = try? file.read(upToCount: textLength) else { continue }
        guard let text = String(data: textData, encoding: .utf8) else { continue }
        
        if text == link {
            return imagesOffset
        }
        
        nextOffset = next
    }
    
    return nil
}

func loadImagesForChapter(imagesOffset: Int, chapterOffset: Int, file: FileHandle) -> [Data]? {
    try? file.seek(toOffset: UInt64(imagesOffset + chapterOffset))
    
    guard let imagesCount = decodeSize(file) else { return nil }
    
    var results = [Data]()
    
    for _ in 0 ..< imagesCount {
        guard let imageSize = decodeSize(file) else { return nil }
        
        guard let imageData = try? file.read(upToCount: imageSize) else { return nil }
        if imageData.count < imageSize { return nil }
        
        results.append(imageData)
    }
    
    return results
}

class OldCache : ObservableObject {
    let path: String?
    var header: CacheOffsets?
    
    @Published var index = [Chapter]()
    var table = [Int]()
    
    func getImages(for link: String) -> [Data]? {
        guard let path = path else { return nil }
        
        guard let file = FileHandle(forReadingAtPath: path) else { return nil }
        
        guard let header = header else { return nil }
        
        guard let imagesIndex = indexHashTable(
            elementsOffset: header.elementsOffset,
            file: file, indices: table, link: link) else { return nil }
        
        return loadImagesForChapter(
            imagesOffset: header.imagesOffset,
            chapterOffset: imagesIndex, file: file)
    }
    
    init?(path: String) {
        self.path = path
        
        guard let file = FileHandle(forReadingAtPath: path) else { return nil }
        
        guard let header = decodeCacheHeader(file: file) else { return nil }
        guard let chapters = decodeChapters(chaptersOffset: header.chaptersOffset, file: file) else { return nil }
        guard let table = decodeHashTable(hashTableOffset: header.tableOffset, file: file) else { return nil }
        
        self.header = header
        self.index = chapters
        self.table = table
        
        try? file.close()
    }
    
    init() {
        self.path = nil
    }
}
