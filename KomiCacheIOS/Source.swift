import CoreGraphics
import Foundation

let indexFileLocation = "index-cache.dat"

struct Chapter : Encodable, Decodable {
    let link: String
    let name: String
    
    let chapter: Int
}

class DataCollector {
    var error: Error?

    let taskCount: Int
    
    let callback: (Int, Data?) -> Void
    
    let maxRetries = 3
    var retries = 0
    
    func startTask(index: Int, task: URL) {
        URLSession.shared.dataTask(with: task) {
            data, response, error in
            
            if let data = data {
                self.retries = 0
                
                self.callback(index, data)
            } else if self.retries < self.maxRetries {
                self.retries += 1
                
                self.startTask(index: index, task: task)
            } else {
                self.callback(index, nil)
            }
        }.resume()
    }
    
    init(tasks: [URL], callback: @escaping (Int, Data?) -> Void) {
        self.callback = callback
        self.taskCount = tasks.count
        
        for (i, task) in tasks.enumerated() {
            startTask(index: i, task: task)
        }
    }
}

protocol Source {
    func makeIndex(callback: @escaping ([Chapter]) -> Void)
    func makeChapterData(link: String,
                         err: @escaping () -> Void,
                         callback: @escaping (Int) -> Void,
                         imageCallback: @escaping (Int, Data?) -> Void)
    func makeChapter(link: String,
                     err: @escaping () -> Void,
                     callback: @escaping (Int) -> Void,
                     imageCallback: @escaping (Int, CGImage?) -> Void)
}

func loadIndex() -> [Chapter]? {
    guard let data = FileManager.default.contents(atPath: indexFileLocation) else { return nil }
    
    let decoder = JSONDecoder()
    return try? decoder.decode(Array<Chapter>.self, from: data)
}

func saveIndex(index: [Chapter]) {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(index) else { return }
    
    FileManager.default.createFile(atPath: indexFileLocation, contents: data)
}

func dataToImage(data: Data) -> CGImage? {
    guard let dataProvider = CGDataProvider(data: data as CFData) else {
        return nil
    }

    // there must be a better way to do this...
    if let image = CGImage(
        jpegDataProviderSource: dataProvider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent) {
        return image
    }
    
    
    if let image = CGImage(
        pngDataProviderSource: dataProvider,
        decode: nil,
        shouldInterpolate: true, intent: .defaultIntent) {
        return image
    }
    
    return nil
}
