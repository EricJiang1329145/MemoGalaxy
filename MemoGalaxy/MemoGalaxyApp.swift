import SwiftUI
import SwiftData

@main
struct MemoGalaxyApp: App {
    @AppStorage("appLanguage") private var appLanguage = "system"
    @State private var currentLocale: Locale = .current

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .appLocale(currentLocale)
                .onAppear {
                    updateLocale()
                }
                .onChange(of: appLanguage) { _, _ in
                    updateLocale()
                }
        }
        .modelContainer(for: EmotionEntry.self)
    }

    private func updateLocale() {
        if appLanguage == "system" {
            currentLocale = .current
        } else if appLanguage == "zh-Hans" {
            currentLocale = Locale(identifier: "zh-Hans")
        } else if appLanguage == "en" {
            currentLocale = Locale(identifier: "en")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}