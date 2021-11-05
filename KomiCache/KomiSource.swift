import Foundation
import SwiftSoup

class KomiSource : Source {
    func makeIndex(callback: @escaping ([Chapter]) -> Void) {
        guard let url = URL(string: "https://komisanmanga.com/") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            guard let text = String(data: data, encoding: .utf8) else { return }
            
            guard let doc = try? SwiftSoup.parse(text) else { return }
            
            guard let elements = try? doc.getElementsByClass("su-post") else { return }
            
            var index = [Chapter]()
            
            for element in elements {
                guard element.tagName() == "li" else { continue }
                
                let links = try? element.getElementsByTag("a")
                guard let link = links?.first() else { continue }
                
                guard let href = try? link.attr("href") else { continue }
                guard let name = try? link.text() else { continue }
                
                let regex = try? NSRegularExpression(pattern: "Chapter ([0-9.])*")
                
                let range = NSRange.init(location: 0, length: name.count)
                guard let match = regex?.firstMatch(in: name, range: range) else { continue }
                
                let chapter = (name as NSString).substring(with: match.range)
                
                let start = chapter.index(chapter.startIndex, offsetBy: "Chapter ".count)
                let end = chapter.endIndex
                
                let chapterText = chapter[start ..< end]
                guard let chapterNumber = Int(chapterText) else { continue }
                
                let value = Chapter(link: href, name: name, chapter: chapterNumber)
                
                index.append(value)
            }
            
            index = index.sorted {
                a, b in
                
                a.chapter < b.chapter
            }
            
            var indexSet = IndexSet()
            
            for i in 0 ..< index.count - 1 {
                // 307-2...
                if !index[i].link.contains("\(index[i].chapter)")
                    || index[i].chapter == index[i + 1].chapter {
                    indexSet.insert(i)
                }
            }
            
            index.remove(atOffsets: indexSet)
            
            callback(index)
        }.resume()
    }
    
    func makeChapterData(link: String,
                         err: @escaping () -> Void,
                         callback: @escaping (Int) -> Void,
                         imageCallback: @escaping (Int, Data?) -> Void) {
        guard let url = URL(string: link) else { return err() }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return err() }
            guard let text = String(data: data, encoding: .utf8) else { return err() }
            
            guard let doc = try? SwiftSoup.parse(text) else { return err() }
            
            guard let elements = try? doc.getElementsByClass("aligncenter") else { return err() }
            
            var urls = [URL]()
            
            for element in elements {
                guard element.tagName() == "img" else { continue }
                
                guard let source = try? element.attr("src") else { continue }
                guard let url = URL(string: source) else { continue }
                
                urls.append(url)
            }
            
            callback(urls.count)
            
            let _ = DataCollector(tasks: urls, callback: imageCallback)
        }.resume()
    }
    
    
    func makeChapter(link: String,
                     err: @escaping () -> Void,
                     callback: @escaping (Int) -> Void,
                     imageCallback: @escaping (Int, CGImage?) -> Void) {
        makeChapterData(link: link, err: err, callback: callback) {
            index, image in
            
            if let image = image {
                let image = dataToImage(data: image)
                
                imageCallback(index, image)
            } else {
                imageCallback(index, nil)
            }
        }
    }
}
