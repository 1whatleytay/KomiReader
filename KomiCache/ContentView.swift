import SwiftUI
import SwiftSoup

struct ChaptersView: View {
    let source: Source
    @ObservedObject var cache: Cache
    
    @State var downloading = Set<Int>()
    @State var isNotDownloading = true
    
    // do i need binding here?
    func download(chapter: Chapter, downloading: Binding<Set<Int>>, cache: Cache) {
        downloading.wrappedValue.insert(chapter.chapter)
        
        var soFar = 0
        var images = [Data]()
        
        source.makeChapterData(link: chapter.link, err: {
            downloading.wrappedValue.remove(chapter.chapter)
        }, callback: {
            count in
            
            images = [Data](repeating: Data(), count: count)
        }) {
            id, data in
            
            guard let data = data else {
                print("Error getting image from chapter \(chapter.link)!")
                downloading.wrappedValue.remove(chapter.chapter)
                return
            }
            
            images[id] = data
            soFar += 1
            
            if soFar >= images.count {
                DispatchQueue.main.async {
                    try? cache.addImages(number: chapter.chapter, images: images)
                }
                
                downloading.wrappedValue.remove(chapter.chapter)
            }
        }
    }
    
    
    var body: some View {
        VStack {
            List {
                ForEach(cache.chapters, id: \.chapter) {
                    chapter in
                    
                    HStack {
                        if downloading.contains(chapter.chapter) {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else if cache.downloaded.contains(chapter.chapter) {
                            Image(systemName: "checkmark.circle")
                                .frame(width: 24, height: 24)
                        } else if isNotDownloading {
                            Image(systemName: "book")
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .frame(width: 24, height: 24)
                        }
                        
                        if isNotDownloading {
                            NavigationLink("Chapter \(chapter.chapter)", destination: {
                                ChapterView(number: chapter.chapter, source: source, cache: cache)
                            })
                                .padding(EdgeInsets.init(top: 0, leading: 6, bottom: 0, trailing: 0))
                        } else {
                            Button(action: {
                                download(chapter: chapter, downloading: $downloading, cache: cache)
                            }, label: {
                                Text("Chapter \(chapter.chapter)")
                            })
                                .padding(EdgeInsets.init(top: 0, leading: 6, bottom: 0, trailing: 0))
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        source.makeIndex {
                            chapters in
                            
                            DispatchQueue.main.async {
                                try? self.cache.dropChapters()
                                try? self.cache.createChapters()
                                try? self.cache.add(chapters: chapters)
                            }
                        }
                    }, label: {
                        Text("Reload")
                    })
                    
                    Spacer()
                }
            }
        }
        .toolbar {
            if isNotDownloading {
                Button(action: {
                    isNotDownloading = false
                }, label: {
                    Text("Download")
                })
            } else {
                Button(action: {
                    isNotDownloading = true
                }, label: {
                    Text("Done")
                })
            }
        }
    }
}

struct ContentView: View {
    @State var number: Int?
    
    let source = KomiSource()
    @StateObject var cache = try! Cache()
    
    var body: some View {
        NavigationView {
            ChaptersView(source: source, cache: cache)
                .navigationTitle("Index")
            
//            IndexView(source: source, cache: cache, number: $number)
//                .navigationTitle("Index")
//
//            ChapterView(number: $number, source: source, cache: cache)
        }
    }
}
