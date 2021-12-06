import SwiftUI
import Foundation

enum ImageState {
    case image(CGImage)
    case loading
    case error
}

struct ImageContainer {
    var index: Int
    var state: ImageState
}

enum ImagesState {
    case loading
    case error
    case images([ImageContainer])
}

struct ChapterView: View {
    let number: Int
    
    var source: Source?
    
    @ObservedObject var cache: Cache
    @State var images = ImagesState.loading
    
    @State var scale: CGFloat = 1.0
    @State var lastScale: CGFloat = 1.0
    
    // Not mutating Cache
    func startLoading(images: Binding<ImagesState>, cache: Cache) {
        images.wrappedValue = .loading

        if let data = try? cache.getImages(number: number) {
            let all = data.map { dataToImage(data: $0) }
            
            var container = [ImageContainer]()
            
            container.reserveCapacity(all.count)
            
            for i in 0 ..< all.count {
                if let image = all[i] as CGImage? {
                    container.append(ImageContainer(index: i, state: .image(image)))
                } else {
                    container.append(ImageContainer(index: i, state: .error))
                }
            }
            
            images.wrappedValue = .images(container)
            
            return
        }
        
        let check = cache.chapters.first { $0.chapter == number }
        guard let chapter = check else { return }
        
        source?.makeChapter(link: chapter.link, err: {
            images.wrappedValue = .error
        }, callback: {
            count in
            
            var container = [ImageContainer]()
            
            container.reserveCapacity(count)
            
            for i in 0 ..< count {
                container.append(ImageContainer(index: i, state: .loading))
            }
            
            images.wrappedValue = .images(container)
        }, imageCallback: {
            index, image in
            
            switch images.wrappedValue {
            case let .images(container):
                // copying like this probably isn't great
                // but I think Data is like NSData or a class
                var newContainer = container
                
                if index >= container.count { return }
                
                if let image = image {
                    newContainer[index].state = .image(image)
                } else {
                    newContainer[index].state = .error
                }
                
                images.wrappedValue = .images(newContainer)
                
            default:
                return
            }
        })
    }
    
    var body: some View {
        VStack(alignment: .center) {
            /*
             if number == nil {
                 Image(systemName: "book")
                     .font(.system(size: 40))
                     .foregroundColor(.gray)
                     .padding(4)
                 
                 HStack(alignment: .center) {
                     Text("Select a Chapter")
                         .font(.system(size: 14))
                         .foregroundColor(.gray)
                 }
             } else
             */
            
            if case .images(let container) = images {
                ZoomableScrollView {
                    List {
                        ForEach(container, id: \.index) { image in
                            if case .image(let image) = image.state {
                                HStack {
                                    Spacer()
                                    
                                    Image(decorative: image, scale: 1)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 800) // oya i wish i could say 
                                    
                                    Spacer()
                                }
                            } else if case .loading = image.state {
                                ProgressView()
                                    .padding()
                            } else if case .error = image.state {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.yellow)
                                    .opacity(0.5)
                                    .padding()
                            }
                        }
                    }
                }
            } else if case .loading = images {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if case .error = images {
                Image(systemName: "exclamationmark.triangle.fill")
            }
        }
        .navigationTitle("Chapter \(number)")
        .onAppear { startLoading(images: $images, cache: cache) }
    }
}
