//
//  ContentView.swift
//  MemoGalaxy
//
//  Created by Eric Jiang on 2025/5/10.
//

// MemoGalaxy.swift
import SwiftUI
import PhotosUI

// 新增emoji到颜色的映射字典（覆盖常用emoji）
private let emojiToColorMap: [String: Color] = [
    "😊": .yellow,    // 开心
    "😢": .blue,      // 悲伤
    "😠": .red,       // 愤怒
    "🥰": .pink,      // 喜爱
    "😌": .mint,      // 平静
    "😲": .orange,    // 惊讶
    "😴": .gray,      // 无聊
    "🎉": .purple,    // 兴奋
    "🤔": .indigo,    // 思考
    "🙏": .green      // 感恩
]

// MARK: - 数据模型
struct EmotionEntry: Identifiable, Codable, Hashable {  // Add Hashable conformance
    let id: UUID
    let title: String  // 新增标题字段
    let content: String
    let emotion: String  // 改为直接存储emoji字符串
    let timestamp: Date
    let imageDataArray: [Data]? // 修改为多张图片数据数组
    var customColor: String?
    var customOpacity: Double = 0.8 // 新增透明度字段，默认最不透明
    var comments: [Comment] = []  // 新增评论数组（默认空）
    enum EmotionType: String, Codable, CaseIterable {
        case happy = "😊"
        case sad = "😢"
        case angry = "😠"
        case love = "🥰"
        case calm = "😌"
        // 新增情绪类型
        case surprised = "😲"  // 惊讶
        case bored = "😴"     // 无聊
        case excited = "🎉"   // 兴奋
        case thoughtful = "🤔"// 思考
        case grateful = "🙏"   // 感恩
        
        var color: Color {
            switch self {
            case .happy: return .yellow
            case .sad: return .blue
            case .angry: return .red
            case .love: return .pink
            case .calm: return .mint
                // 新增颜色对应
            case .surprised: return .orange
            case .bored: return .gray
            case .excited: return .purple
            case .thoughtful: return .indigo
            case .grateful: return .green
            }
        }
    }
}
// 新增评论数据模型（修复Hashable一致性）
struct Comment: Identifiable, Codable, Hashable {  // 添加Hashable协议
    let id: UUID          // 评论唯一标识（UUID符合Hashable）
    let content: String   // 评论内容（String符合Hashable）
    let timestamp: Date   // 评论时间（Date符合Hashable）
}



// MARK: - 数据管理
class DiaryManager: ObservableObject {
    @Published var entries: [EmotionEntry] = []
    private let saveDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    func updateEntry(_ updatedEntry: EmotionEntry) {
        guard let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) else { return }
        entries[index] = updatedEntry
        saveData()  // 触发数据持久化
    }
    init() {
    
        loadData()
        // 添加前台通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadDataOnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        // 移除通知监听
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // 新增前台触发加载方法
    @objc private func loadDataOnForeground() {
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
    @State private var entryToDelete: EmotionEntry?
    @State private var isLoading = true
    @State private var selectedEntry: EmotionEntry?
    @State private var searchText = ""
    
    var body: some View {
        // iOS 18+ 推荐的标签栏结构
        TabView {
            // 主界面标签页
            NavigationSplitView {
                // 侧边栏（左侧）
                List(manager.entries, selection: $selectedEntry) { entry in
                    NavigationLink(value: entry) {
                        EntryRow(entry: entry)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            entryToDelete = entry
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                .navigationTitle("日记列表")
                .toolbar {
                    // 右上角添加按钮保留
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
                    if manager.entries.isEmpty {
                        ContentUnavailableView(
                            "开启你的星云之旅",
                            systemImage: "moon.stars",
                            description: Text("点击+号记录心情日记")
                        )
                    }
                }
            } detail: {
                // 详情页（右侧）
                if let entry = selectedEntry {
                    DetailView(entry: entry, manager: manager)  // 传递manager
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
            
            // 设置标签页
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .sheet(isPresented: $showingAddView) {
            AddEntryView(manager: manager)
        }
        .onReceive(manager.$entries) { _ in
            isLoading = false
            if !manager.entries.isEmpty && selectedEntry == nil {
                selectedEntry = manager.entries.first
            }
        }
        .confirmationDialog(
            "确认删除",
            isPresented: .constant(entryToDelete != nil),
            presenting: entryToDelete
        ) { entry in
            Button("删除", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    manager.deleteEntry(entry)
                }
                entryToDelete = nil
                selectedEntry = nil
            }
            Button("取消", role: .cancel) {
                entryToDelete = nil
            }
        } message: { entry in
            Text("确定要永久删除\(entry.timestamp.formatted(date: .abbreviated, time: .omitted))的日记吗？")
        }
    }
}

// MARK: - 列表项组件
struct EntryRow: View {
    let entry: EmotionEntry
    @State private var isTapped = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(entry.emotion)
                .font(.system(size: 40, design: .default))
                .padding(5)
                .background(
                    // 改为从字典获取颜色，无匹配时使用默认灰色
                    entry.customColor != nil
                    ? Color(hex: entry.customColor!).opacity(entry.customOpacity)
                    : (emojiToColorMap[entry.emotion] ?? .gray).opacity(entry.customOpacity)
                )
                .clipShape(Circle())
                .scaleEffect(isTapped ? 1.1 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isTapped)
                .onTapGesture {
                    isTapped.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTapped = false
                    }
                }
            
            VStack(alignment: .leading) {
                // 修改时间显示格式
                Text(DateFormatter.chineseDate.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(entry.title)
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
    @ObservedObject var manager: DiaryManager
    @State private var newComment = ""      // 评论输入状态
    @State private var previewImage: UIImage?  // 全屏预览状态
    @State private var currentCarouselIndex = 0  // 轮播图当前索引
    private var currentEntry: EmotionEntry? {
        manager.entries.first { $0.id == entry.id }
    }
    // 中文日期格式化器
    private var chineseDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH时mm分ss秒"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    // 主题色全屏背景（修复颜色获取）
                    (entry.customColor != nil ?
                     Color(hex: entry.customColor!) :
                        (emojiToColorMap[entry.emotion] ?? .gray))
                    .opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
                    
                    // 内容卡片
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top) {
                            Text(entry.emotion)  // 已改为直接显示字符串
                                .font(.system(size: 60, weight: .bold))
                                .padding(10)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            entry.customColor != nil ? Color(hex: entry.customColor!) : (emojiToColorMap[entry.emotion] ?? .gray),  // 修复颜色
                                            entry.customColor != nil ? Color(hex: entry.customColor!).opacity(0.7) : (emojiToColorMap[entry.emotion] ?? .gray).opacity(0.7)  // 修复颜色
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(entry.customOpacity)
                                )
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                // 替换为实际日记标题
                                Text(entry.title)
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
                            
                            // 所有图片动态布局（保留原有逻辑）
                            if let imageDataArray = entry.imageDataArray, !imageDataArray.isEmpty {
                                if imageDataArray.count >= 3 {
                                    // 轮播图（≥3张）
                                    TabView(selection: $currentCarouselIndex) {
                                        ForEach(imageDataArray.indices, id: \.self) { index in
                                            if let uiImage = UIImage(data: imageDataArray[index]) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .cornerRadius(12)
                                                    .tag(index)
                                                    .onTapGesture { previewImage = uiImage }
                                            }
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .always))
                                    .frame(height: 250)
                                } else {
                                    // 网格布局（1-2张）
                                    LazyVGrid(columns: imageDataArray.count == 1
                                              ? [GridItem(.flexible())]
                                              : [GridItem(.flexible()), GridItem(.flexible())],
                                              spacing: 8) {
                                        ForEach(imageDataArray.indices, id: \.self) { index in
                                            if let uiImage = UIImage(data: imageDataArray[index]) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: imageDataArray.count == 1 ? 250 : 150)
                                                    .clipped()
                                                    .cornerRadius(12)
                                                    .onTapGesture { previewImage = uiImage }
                                            }
                                        }
                                    }
                                }
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
                            VStack(alignment: .leading) {  
                                Text("评论")
                                    .font(.headline)
                                    .padding(.top)
                                
                                HStack {
                                    TextField("写下你的评论...", text: $newComment)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Button {
                                        guard !newComment.isEmpty, var updatedEntry = currentEntry else { return }
                                        
                                        let comment = Comment(
                                            id: UUID(),
                                            content: newComment,
                                            timestamp: Date()
                                        )
                                        updatedEntry.comments.append(comment)
                                        manager.updateEntry(updatedEntry)
                                        newComment = ""
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                    }
                                    .disabled(newComment.isEmpty)
                                }
                                
                                if let entry = currentEntry {
                                    ForEach(entry.comments) { comment in
                                        VStack(alignment: .leading) {
                                            Text(comment.content)
                                                .padding(8)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                            
                                            Text(comment.timestamp.formatted())
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 4)
                                        .animation(.easeInOut, value: currentEntry?.comments.count)
                                    }
                                }
                            }
                            .padding()
                            
                            
                            // 调整文末图片展示（跳过第一张）
                            if let imageDataArray = entry.imageDataArray, imageDataArray.count > 1 {
                                ForEach(1..<imageDataArray.count, id: \.self) { index in
                                    if let uiImage = UIImage(data: imageDataArray[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(12)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                        // 将导航标题移到正确位置
                    }
                }
                .padding(20) // 增大外层间距
                .background(
                    RoundedRectangle(cornerRadius: 24) // 增大圆角半径
                        .fill(Color(.systemBackground).opacity(0.5)) // 设置半透明
                )
                .padding(.horizontal)
                .navigationTitle(entry.title) // 将修饰符移动到 NavigationStack 的子视图上
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { /* 移除原有的 ToolbarItem */ }
                .background(
                    // 修复此处：使用emojiToColorMap替代emotion.color
                    (entry.customColor != nil ?
                     Color(hex: entry.customColor!) :
                        (emojiToColorMap[entry.emotion] ?? .gray))
                    .opacity(0.1)
                )
            }
            .padding(.top, 40)
        }
    }
    // 设置导航栏标题为日记标题
    
    
    
    
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
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedEmoji = "😊"  // 默认emoji
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedColor: String?
    @State private var selectedOpacity: Double = 0.8
    @State private var imageCompression: Double = 0.8  // 新增压缩质量状态
    
    // 常用emoji快捷选项（可根据需求扩展）
    private let commonEmojis = ["😊", "😢", "😠", "🥰", "😌", "😲", "😴", "🎉", "🤔", "🙏"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("你的心情") {
                    // 新增emoji输入框（添加输入限制）
                    TextField("输入任意emoji", text: $selectedEmoji)
                        .textFieldStyle(.roundedBorder)
                        .font(.largeTitle)
                    // 限制只能输入1个emoji（适配iOS 17+双参数闭包）
                        .onChange(of: selectedEmoji) { oldValue, newValue in  // 修改此处：添加旧值参数
                            if newValue.count > 1 {
                                selectedEmoji = String(newValue.prefix(1))
                            }
                        }
                    
                    // 常用emoji快捷选择（保持不变）
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(commonEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title)
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedEmoji = emoji  // 点击直接设置单个emoji
                                    }
                            }
                        }
                    }
                    .padding(.top, 8)
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
                                VStack(spacing: 4) {
                                    ColorCircle(
                                        color: hex,
                                        colorName: name,
                                        isSelected: selectedColor == hex
                                    )
                                    .scaleEffect(selectedColor == hex ? 1.05 : 1)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedColor = hex
                                        }
                                    }
                                    
                                    Text(name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 新增图片压缩质量设置区域
                Section("图片设置") {
                    HStack {
                        Text("图片质量")
                        Slider(
                            value: $imageCompression,
                            in: 0.1...1,
                            step: 0.1
                        )
                        Text(String(format: "%.1f", imageCompression))
                    }
                    Text("1.0为无损质量，0.1为高度压缩（文件更小）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    // 适配iOS 17+的onChange新语法（接受新旧值参数）
                    .onChange(of: photoItems) { oldItems, newItems in
                        Task {
                            var loadedImages: [UIImage] = []
                            for item in newItems {
                                // 加载图片数据并转换为UIImage
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    loadedImages.append(image)
                                }
                            }
                            // 主线程更新selectedImages
                            await MainActor.run {
                                selectedImages = loadedImages
                            }
                        }
                    }
                    
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
                        // 实时预览颜色+透明度效果（修复变量名）
                        Circle()
                            .fill(
                                selectedColor != nil
                                ? Color(hex: selectedColor!)
                                : (emojiToColorMap[selectedEmoji] ?? .gray)  // 使用selectedEmoji获取颜色
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
                        .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func saveEntry() {
        let imageDataArray = selectedImages.compactMap {
            $0.jpegData(compressionQuality: imageCompression)  // 使用用户选择的压缩质量
        }
        let newEntry = EmotionEntry(
            id: UUID(),
            title: title,
            content: content,
            emotion: selectedEmoji,
            timestamp: Date(),
            imageDataArray: imageDataArray,
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

// MARK: - 列表项预览
struct EntryRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 日常工作压力场景
            EntryRow(entry: EmotionEntry(
                id: UUID(),
                title: "项目上线日",
                content: "连续三周的加班终于迎来成果，系统顺利上线！虽然疲惫但充满成就感，团队协作中学习到很多架构设计经验。",
                emotion: "😌",
                timestamp: Date().addingTimeInterval(-86400),
                imageDataArray: [UIImage(systemName: "laptopcomputer")?.pngData()!].compactMap { $0 }
            ))
            
            // 周末生活场景
            EntryRow(entry: EmotionEntry(
                id: UUID(),
                title: "家庭聚餐日",
                content: "和父母一起准备火锅晚餐，听他们讲述年轻时的故事。发现代沟其实也是理解的桥梁。",
                emotion: "🥰",
                timestamp: Date().addingTimeInterval(-172800),
                imageDataArray: [UIImage(systemName: "house.fill")?.pngData()!].compactMap { $0 },
                customColor: "#FF69B4"
            ))
        }
        .previewDisplayName("生活场景预览")
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        // 旅行回忆场景
        let travelEntry = EmotionEntry(
            id: UUID(),
            title: "富士山之旅",
            content: "清晨五点的河口湖，目睹'赤富士'奇观。\n登山注意事项：\n1. 携带充足饮用水\n2. 注意高原反应\n3. 遵守登山礼仪\n难忘的云海日出体验！",
            emotion: "🎉",
            timestamp: Date().addingTimeInterval(-259200),
            imageDataArray: (1...3).compactMap {
                UIImage(systemName: ["mountain.2", "photo", "leaf"][$0-1])?.pngData()
            },
            customColor: "#FF6600",
            customOpacity: 0.6
        )
        
        // 新增DiaryManager实例并传递给DetailView
        DetailView(entry: travelEntry, manager: DiaryManager())
            .previewDisplayName("旅行日记预览")
    }
}

// 在文件底部添加（或在现有预览代码后修改）
#if DEBUG
#Preview("带图片的列表项") {
    EntryRow(entry: EmotionEntry(
        id: UUID(),
        title: "图片测试",
        content: "带图片的列表项预览",
        emotion: "🤔",
        timestamp: Date(),
        imageDataArray: [UIImage(systemName: "photo")!.pngData()!]
    ))
}
#endif
