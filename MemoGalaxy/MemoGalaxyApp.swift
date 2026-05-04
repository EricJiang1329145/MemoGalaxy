import SwiftUI
import SwiftData

@main
struct MemoGalaxyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: EmotionEntry.self)
    }
}
