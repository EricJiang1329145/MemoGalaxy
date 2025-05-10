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
    var customColor: String?
    var customOpacity: Double = 0.8 // 新增透明度字段，默认最不透明
    
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
    private let saveDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadData()
    }
    
    private func loadData() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: saveDirectory, 
                                                                       includingPropertiesForKeys: nil)
            entries = fileURLs
                .filter { $0.pathExtension == "json" }
                .compactMap { url -> EmotionEntry? in
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    return try? JSONDecoder().decode(EmotionEntry.self, from: data)
                }
                .sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("加载数据失败: \(error)")
        }
    }
    
    private func saveData() {
        entries.forEach { entry in
            let fileURL = saveDirectory
                .appendingPathComponent(entry.id.uuidString)
                .appendingPathExtension("json")
            do {
                let data = try JSONEncoder().encode(entry)
                try data.write(to: fileURL)
            } catch {
                print("保存失败: \(error)")
            }
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
                .background(
                    entry.customColor != nil 
                        ? Color(hex: entry.customColor!).opacity(entry.customOpacity) 
                        : entry.emotion.color.opacity(entry.customOpacity)
                )
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
            ZStack {
                // 主题色全屏背景
                (entry.customColor != nil ? 
                    Color(hex: entry.customColor!) : 
                    entry.emotion.color)
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)
                
                // 内容卡片
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(entry.emotion.rawValue)
                            .font(.system(size: 60))
                            .padding(10)
                            .background(
                                entry.customColor != nil ? 
                                    Color(hex: entry.customColor!).opacity(entry.customOpacity) : 
                                    entry.emotion.color.opacity(entry.customOpacity)
                            )
                            .clipShape(Circle())
                        
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)
                    
                    // 卡片式内容区域
                    VStack(alignment: .leading, spacing: 15) {
                        Text("日记内容")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(entry.content)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .primary.opacity(0.1), radius: 6, x: 0, y: 2)
                            )
                        
                        if let imageData = entry.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Text("附加图片")
                                .font(.headline)
                                .padding(.top)
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 40)
            }
        }
        .navigationTitle("日记详情")
        .background(
            (entry.customColor != nil ? 
                Color(hex: entry.customColor!) : 
                entry.emotion.color)
                .opacity(0.05)
                .edgesIgnoringSafeArea(.all)
        )
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
    @State private var selectedColor: String?
    @State private var selectedOpacity: Double = 0.8 // 新增透明度状态
    
    let presetColors = [
        ("初音绿", "#39C5BB"),
        ("克莱因蓝", "#002FA7"),
        ("蒂芙尼蓝", "#81D8D0"),
        ("长春花蓝", "#6667AB"),
        ("马尔斯绿", "#01847F"),
        ("勃艮第红", "#900020"),
        ("波尔多红", "#4C1A24"),
        ("爱马仕橙", "#E35335")
    ]
    
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
                
                Section("选择主题颜色") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ColorPicker("自定义颜色", selection: Binding(
                                get: { Color(hex: selectedColor ?? "#FFFFFF") },
                                set: { selectedColor = $0.toHex() }
                            ))
                            .frame(width: 44, height: 44)
                            
                            // 传递颜色名称给ColorCircle
                            ForEach(presetColors, id: \.1) { name, hex in
                                ColorCircle(
                                    color: hex,
                                    colorName: name, // 新增颜色名称参数
                                    isSelected: selectedColor == hex
                                )
                                .onTapGesture {
                                    selectedColor = hex
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
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
                
                Section("选择透明度") {
                    HStack {
                        Text("不透明度")
                        Slider(
                            value: $selectedOpacity,
                            in: 0...1,
                            step: 0.1
                        )
                        Text(String(format: "%.1f", selectedOpacity))
                    }
                    
                    HStack {
                        Text("预览：")
                        // 实时预览颜色+透明度效果
                        Circle()
                            .fill(
                                selectedColor != nil 
                                    ? Color(hex: selectedColor!) 
                                    : selectedEmotion.color
                            )
                            .frame(width: 44, height: 44)
                            .opacity(selectedOpacity)
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
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            customColor: selectedColor,
            customOpacity: selectedOpacity // 保存透明度
        )
        manager.saveEntry(newEntry)
        dismiss()
    }
}

struct ColorCircle: View {
    @Environment(\.colorScheme) var colorScheme // 新增环境变量
    let color: String
    let colorName: String
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
            
            if isSelected {
                VStack(spacing: 4) {
                    Text(colorName)
                        .font(.caption2)
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? 
                                    Color.black.opacity(0.7) : 
                                    Color.white.opacity(0.9)) // 适配深浅模式
                                .shadow(radius: 2)
                        )
                        .foregroundColor(colorScheme == .dark ? 
                                       .white : .black) // 文字颜色适配
                        .offset(y: 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundColor(colorScheme == .dark ? 
                                       Color.black.opacity(0.7) : 
                                       Color.white.opacity(0.9)) // 箭头颜色适配
                        .offset(y: 24)
                }
            }
        }
    }
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
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
