import SwiftUI
import SwiftSoup

struct ContentView : View {
    @State var number: Int?
    
    let source = KomiSource()
    @StateObject var cache = try! Cache()
    
    var body: some View {
        NavigationView {
            IndexView(source: source, cache: cache, number: $number)
                .navigationTitle("Index")
            
            ChapterView(number: $number, source: source, cache: cache)
        }
    }
}
