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
    let title: String  // 新增标题字段
    let content: String
    let emotion: EmotionType
    let timestamp: Date
    let imageDataArray: [Data]? // 修改为多张图片数据数组
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
        // 使用后台队列执行文件操作
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: self.saveDirectory, 
                                                                           includingPropertiesForKeys: nil)
                let loadedEntries = fileURLs
                    .filter { $0.pathExtension == "json" }
                    .compactMap { url -> EmotionEntry? in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        return try? JSONDecoder().decode(EmotionEntry.self, from: data)
                    }
                    .sorted { $0.timestamp > $1.timestamp }
                
                // 回到主线程更新@Published属性
                DispatchQueue.main.async {
                    self.entries = loadedEntries
                }
            } catch {
                print("加载数据失败: \(error)")
            }
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
    @State private var entryToDelete: EmotionEntry?  // 新增删除状态跟踪
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.entries) { entry in
                    NavigationLink(destination: DetailView(entry: entry)) {
                        EntryRow(entry: entry)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            entryToDelete = entry  // 改为触发确认对话框
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .overlay {
                if manager.entries.isEmpty {
                    ContentUnavailableView(
                        "开启你的星云之旅",
                        systemImage: "moon.stars",
                        description: Text("点击右下角的+号记录你的心情日记")
                    )
                }
            }
            .confirmationDialog(
                "确认删除",
                isPresented: .constant(entryToDelete != nil),
                presenting: entryToDelete
            ) { entry in
                Button("删除", role: .destructive) {
                    manager.deleteEntry(entry)
                    entryToDelete = nil
                }
                Button("取消", role: .cancel) {
                    entryToDelete = nil
                }
            } message: { entry in
                Text("确定要永久删除\(entry.timestamp.formatted(date: .abbreviated, time: .omitted))的日记吗？")
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
                // 修改时间显示格式
                Text(DateFormatter.chineseDate.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(entry.content)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            if let imageDataArray = entry.imageDataArray, let firstImageData = imageDataArray.first, let uiImage = UIImage(data: firstImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            }
        }
    }
}

// MARK: - 详情页
struct DetailView: View {
    let entry: EmotionEntry
    
    // 中文日期格式化器
    private var chineseDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH时mm分ss秒"
        return formatter
    }
    
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
                    HStack(alignment: .top) {
                        Text(entry.emotion.rawValue)
                            .font(.system(size: 60))
                            .padding(10)
                            .background(
                                entry.customColor != nil ? 
                                    Color(hex: entry.customColor!).opacity(entry.customOpacity) : 
                                    entry.emotion.color.opacity(entry.customOpacity)
                            )
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            // 新增标题在表情右侧
                            Text("日记详情")
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .padding(.bottom, 4)
                            
                            // 调整时间显示位置
                            Text(chineseDateTimeFormatter.string(from: entry.timestamp))
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                    .padding(.bottom)
                    
                    // 卡片式内容区域
                    VStack(alignment: .leading, spacing: 15) {
                        // 首端只显示第一张照片
                        if let firstImageData = entry.imageDataArray?.first, let uiImage = UIImage(data: firstImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .padding(.bottom)
                        }
                        
                        // 正文内容
                        Text(entry.content)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .primary.opacity(0.1), radius: 6, x: 0, y: 2)
                            )
                        
                        // 正文后显示所有照片（包含第一张）
                        if let imageDataArray = entry.imageDataArray {
                            ForEach(0..<imageDataArray.count, id: \.self) { index in
                                if let uiImage = UIImage(data: imageDataArray[index]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(12)
                                        .padding(.vertical, 8) // 减小垂直间距为8点
                                }
                            }
                        }
                    }
                    .padding(20) // 增大外层间距
                    .background(
                        RoundedRectangle(cornerRadius: 24) // 增大圆角半径
                            .fill(Color(.systemBackground).opacity(0.5)) // 设置半透明
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 40)
            }
        }
        // 移除原有导航栏标题设置
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* 移除原有的 ToolbarItem */ }
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
// 在合适的位置添加预设颜色数组
let presetColors: [(String, String)] = [
    // 新增赛车主题色
    ("法拉利红", "#FF2800"),     // Scuderia Ferrari Red
    ("迈凯轮橙", "#FF8700"),     // McLaren Papaya Orange
    ("梅赛德斯银", "#00D2BE"),   // Mercedes-AMG Petronas Silver
    ("红牛蓝", "#0600EF"),       // Red Bull Racing Blue
    
    // 新增EVA主题色
    ("EVA初号机紫", "#5F3D7A"), // Evangelion Unit-01 Purple 
    ("EVA零号机黄", "#FFD700"), // Evangelion Unit-00 Yellow
    ("EVA二号机红", "#C41E3A"), // Evangelion Unit-02 Red
    ("NERV标志橙", "#FF6600"),  // NERV Organization Orange
    
    // 保留现有颜色
    ("初音绿", "#39C5BB"),
    ("克莱因蓝", "#002FA7"),
    ("蒂芙尼蓝", "#81D8D0"),
    ("长春花蓝", "#6667AB"),
    ("马尔斯绿", "#008C8C"),
    ("勃艮第红", "#900020"),
    ("波尔多红", "#5D1F1C"),
    ("爱马仕橙", "#E8590C"),
    // 原有保留颜色
    ("红色", "#FF0000"),
    ("绿色", "#00FF00"), 
    ("蓝色", "#0000FF")
]

struct AddEntryView: View {
    @ObservedObject var manager: DiaryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""  // 新增标题状态
    @State private var content = ""
    @State private var selectedEmotion: EmotionEntry.EmotionType = .happy
    @State private var selectedImage: UIImage?
    @State private var photoItems: [PhotosPickerItem] = [] // 存储多个图片选择项
    @State private var selectedImages: [UIImage] = [] // 存储多个选中的图片
    // 新增 selectedColor 变量
    @State private var selectedColor: String?
    @State private var selectedOpacity: Double = 0.8
    
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
                
                // 合并后的标题+正文区域
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        // 标题输入
                        TextField("输入日记标题", text: $title)
                            .textFieldStyle(.roundedBorder)
                        
                        // 分隔线
                        Divider()
                        
                        // 正文输入
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("请输入正文")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                        }
                    }
                }
                
                Section("添加图片") {
                    PhotosPicker(
                        "选择照片",
                        selection: $photoItems,
                        matching: .images,
                        photoLibrary: .shared()
                    )
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(12)
                                }
                            }
                        }
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
                        .disabled(content.isEmpty || title.isEmpty)  // 同时检查标题和正文是否为空
                }
            }
            .task(id: photoItems) {
                selectedImages.removeAll()
                for item in photoItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let imageDataArray = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let newEntry = EmotionEntry(
            id: UUID(),
            title: title,
            content: content,
            emotion: selectedEmotion,
            timestamp: Date(),
            imageDataArray: imageDataArray.isEmpty ? nil : imageDataArray,
            customColor: selectedColor,
            customOpacity: selectedOpacity
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
        // 修改选中状态样式
        ZStack {
            Circle()
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                .frame(width: 54, height: 54)
            
            Circle()
                .fill(Color(hex: color))
                .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)
                .shadow(color: .primary.opacity(0.2), radius: isSelected ? 8 : 4, x: 0, y: 2)
                .animation(.spring(), value: isSelected)
            
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
extension DateFormatter {
    static let chineseDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()
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
