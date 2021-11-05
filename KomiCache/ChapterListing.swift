import SwiftUI
import Foundation

struct ChapterListing: View {
    let source: Source?
    
    @State var downloading = false
    
    @Binding var chapter: Chapter
    @ObservedObject var cache: Cache
    
    // do i need binding here?
    func download(chapter: Chapter, cache: Cache) {
        downloading = true
        
        var soFar = 0
        var images = [Data]()
        
        guard let source = source else {
            downloading = false
            return
        }
        
        source.makeChapterData(link: chapter.link, err: { downloading = false }, callback: {
            count in
            
            images = [Data](repeating: Data(), count: count)
        }) {
            id, data in
            
            guard let data = data else {
                print("Error getting image from chapter \(chapter.link)!")
                downloading = false
                return
            }
            
            images[id] = data
            soFar += 1
            
            if soFar >= images.count {
                DispatchQueue.main.async {
                    try? cache.addImages(number: chapter.chapter, images: images)
                }
                
                downloading = false
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if cache.downloaded.contains(chapter.chapter) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)
                    .padding(4)
            } else if downloading {
                ProgressView()
                    .frame(width: 24, height: 24)
                    .padding(4)
            } else {
                Button {
                    download(chapter: chapter, cache: cache)
                } label: {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 20))
                        .frame(width: 24, height: 24)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        
            Text("Chapter \(chapter.chapter)")
                .font(.system(size: 14))
        }
    }
}
