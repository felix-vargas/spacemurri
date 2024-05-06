import SwiftUI
  
@main
struct SpaceMurriApp: App {
    // Register the AppDelegate for the NSApplicationDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
    var body: some Scene {
        // Provide an empty scene
        Settings {
            EmptyView()
        }
    }
}
