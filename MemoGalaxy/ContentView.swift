//
//  ContentView.swift
//  MemoGalaxy
//
//  Created by Eric Jiang on 2025/5/10.
//

// MemoGalaxy.swift
import SwiftUI
import PhotosUI

// MARK: - 数据模型
struct EmotionEntry: Identifiable, Codable {
    let id: UUID
    let content: String
    let emotion: EmotionType
    let timestamp: Date
    var imageData: Data?
    
    enum EmotionType: String, Codable, CaseIterable {
        case happy = "😊"
        case sad = "😢"
        case angry = "😠"
        case love = "🥰"
        case calm = "😌"
        
        var color: Color {
            switch self {
            case .happy: return .yellow
            case .sad: return .blue
            case .angry: return .red
            case .love: return .pink
            case .calm: return .mint
            }
        }
    }
}

// MARK: - 数据管理
class DiaryManager: ObservableObject {
    @Published var entries: [EmotionEntry] = []
    private let saveKey = "MemoGalaxyData"
    
    init() {
        loadData()
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([EmotionEntry].self, from: data) {
            entries = decoded
        }
    }
    
    func saveEntry(_ entry: EmotionEntry) {
        entries.insert(entry, at: 0)
        saveData()
    }
    
    func deleteEntry(_ entry: EmotionEntry) {
        entries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var manager = DiaryManager()
    @State private var showingAddView = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.entries) { entry in
                    NavigationLink(destination: DetailView(entry: entry)) {
                        EntryRow(entry: entry)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            manager.deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("MemoGalaxy 🌌")
            .toolbar {
                Button {
                    showingAddView = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddEntryView(manager: manager)
            }
        }
    }
}

// MARK: - 列表项组件
struct EntryRow: View {
    let entry: EmotionEntry
    
    var body: some View {
        HStack(alignment: .top) {
            Text(entry.emotion.rawValue)
                .font(.system(size: 40))
                .padding(5)
                .background(entry.emotion.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(entry.content)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            if entry.imageData != nil {
                Spacer()
                Image(systemName: "photo")
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - 详情页
struct DetailView: View {
    let entry: EmotionEntry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(entry.emotion.rawValue)
                        .font(.system(size: 60))
                    Text(entry.timestamp.formatted())
                        .foregroundStyle(.secondary)
                }
                
                Text(entry.content)
                    .font(.title3)
                
                if let imageData = entry.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("日记详情")
    }
}

// MARK: - 添加新日记
struct AddEntryView: View {
    @ObservedObject var manager: DiaryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var content = ""
    @State private var selectedEmotion: EmotionEntry.EmotionType = .happy
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("你的心情") {
                    Picker("选择情绪", selection: $selectedEmotion) {
                        ForEach(EmotionEntry.EmotionType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical)
                }
                
                Section("日记内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                Section("添加图片") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(selectedImage == nil ? "选择照片" : "更换照片", systemImage: "photo")
                    }
                    
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("新日记")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("保存") { saveEntry() }
                        .disabled(content.isEmpty)
                }
            }
            .task(id: photoItem) {
                if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                }
            }
        }
    }
    
    private func saveEntry() {
        let newEntry = EmotionEntry(
            id: UUID(),
            content: content,
            emotion: selectedEmotion,
            timestamp: Date(),
            imageData: selectedImage?.jpegData(compressionQuality: 0.8)
        )
        manager.saveEntry(newEntry)
        dismiss()
    }
}
@main
struct MemoGalaxy: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 预览
#Preview {
    ContentView()
}
