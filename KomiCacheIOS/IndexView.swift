//import SwiftUI
//import Foundation
//
//struct IndexView: View {
//    let source: Source?
//    
//    @ObservedObject var cache: Cache
//    @Binding var number: Int?
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Text("Index")
//                    .fontWeight(.bold)
//                    .font(.system(size: 32))
//                
//                Spacer()
//                
//                Button {
//                    source?.makeIndex { chapters in
//                        DispatchQueue.main.async {
//                            try! cache.dropChapters()
//                            try! cache.createChapters()
//                            try! cache.add(chapters: chapters)
//                        }
//                    }
//                } label: {
//                    HStack(alignment: .center) {
//                        Image(systemName: "arrow.clockwise.circle")
//                    }
//                }
////                .buttonStyle(LinkButtonStyle())
//            }
//            .padding(20)
//            
//            VStack(alignment: .center) {
//                if cache.chapters.isEmpty {
//                    Image(systemName: "archivebox")
//                        .font(.system(size: 40))
//                        .foregroundColor(.gray)
//                        .padding(4)
//                    
//                    HStack(alignment: .center) {
//                        Text("Index is Empty Right Now")
//                            .font(.system(size: 14))
//                            .foregroundColor(.gray)
//                    }
//                    .padding(EdgeInsets.init(top: 0, leading: 0, bottom: 60, trailing: 0))
//                } else {
//                    List($cache.chapters, id: \.chapter, selection: $number) { chapter in
//                        ChapterListing(source: source, chapter: chapter, cache: cache)
//                    }
//                }
//            }
//            .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
//            .padding(EdgeInsets.init(top: 0, leading: 12, bottom: 4, trailing: 12))
//            
//            Spacer()
//        }
//        .frame(minWidth: 300, minHeight: 200)
//        .background(Color.white)
//    }
//}
