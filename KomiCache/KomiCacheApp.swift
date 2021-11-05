import SwiftUI

@main
struct KomiCacheApp: App {
    @NSApplicationDelegateAdaptor(KomiCacheDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class KomiCacheDelegate : NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
