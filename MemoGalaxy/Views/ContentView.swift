import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \EmotionEntry.timestamp, order: .reverse) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddView = false
    @State private var entryToDelete: EmotionEntry?
    @State private var showDeleteConfirmation = false
    @State private var selectedEntry: EmotionEntry?
    @State private var searchText = ""

    private var filteredEntries: [EmotionEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        TabView {
            NavigationSplitView {
                List(selection: $selectedEntry) {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(value: entry) {
                            EntryRow(entry: entry)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationTitle("日记列表")
                .searchable(text: $searchText, prompt: "搜索标题或内容")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showingAddView = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
                .overlay {
                    if entries.isEmpty {
                        ContentUnavailableView(
                            "开启你的星云之旅",
                            systemImage: "moon.stars",
                            description: Text("点击+号记录心情日记")
                        )
                    }
                }
            } detail: {
                if let entry = selectedEntry {
                    DetailView(entry: entry)
                } else {
                    ContentUnavailableView(
                        "选择日记查看详情",
                        systemImage: "doc.text"
                    )
                }
            }
            .tabItem {
                Label("日记", systemImage: "list.dash")
            }

            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .sheet(isPresented: $showingAddView) {
            AddEntryView()
        }
        .onChange(of: entries) { _, newEntries in
            if !newEntries.isEmpty && selectedEntry == nil {
                selectedEntry = newEntries.first
            }
        }
        .confirmationDialog(
            "确认删除",
            isPresented: $showDeleteConfirmation,
            presenting: entryToDelete
        ) { entry in
            Button("删除", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    modelContext.delete(entry)
                }
                entryToDelete = nil
                selectedEntry = nil
            }
            Button("取消", role: .cancel) {
                entryToDelete = nil
            }
        } message: { entry in
            let dateStr = entry.timestamp.formatted(date: .abbreviated, time: .omitted)
            Text("确定要永久删除\(dateStr)的日记吗？")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("列表项预览") {
    EntryRow(entry: EmotionEntry(
        title: "项目上线日",
        content: "连续三周的加班终于迎来成果，系统顺利上线！",
        emotion: "😌",
        timestamp: Date().addingTimeInterval(-86400),
        imageDataArray: [UIImage(systemName: "laptopcomputer")?.pngData()!].compactMap { $0 }
    ))
}

#Preview("详情预览") {
    let travelEntry = EmotionEntry(
        title: "富士山之旅",
        content: "清晨五点的河口湖，目睹'赤富士'奇观。\n难忘的云海日出体验！",
        emotion: "🎉",
        timestamp: Date().addingTimeInterval(-259200),
        imageDataArray: (1...3).compactMap {
            UIImage(systemName: ["mountain.2", "photo", "leaf"][$0-1])?.pngData()
        },
        customColor: "#FF6600",
        customOpacity: 0.6
    )
    DetailView(entry: travelEntry)
}
