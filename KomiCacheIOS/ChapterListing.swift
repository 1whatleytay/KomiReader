//import SwiftUI
//import Foundation
//
//struct ChapterListing: View {
//    let source: Source?
//    
//    @State var downloading = false
//    
//    @Binding var chapter: Chapter
//    @ObservedObject var cache: Cache
//    
//    var body: some View {
//        HStack(alignment: .center) {
//            if cache.downloaded.contains(chapter.chapter) {
//                Image(systemName: "checkmark.circle")
//                    .font(.system(size: 20))
//                    .frame(width: 24, height: 24)
//                    .padding(4)
//            } else if downloading {
//                ProgressView()
//                    .frame(width: 24, height: 24)
//                    .padding(4)
//            } else {
//                Button {
////                    download(chapter: chapter, cache: cache)
//                } label: {
//                    Image(systemName: "icloud.and.arrow.down")
//                        .font(.system(size: 20))
//                        .frame(width: 24, height: 24)
//                        .padding(4)
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//        
//            Text("Chapter \(chapter.chapter)")
//                .font(.system(size: 14))
//        }
//    }
//}
