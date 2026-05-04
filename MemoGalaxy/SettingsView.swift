import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("enableHaptic") private var enableHaptic = true
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("disableOCR") private var disableOCR = false
    @AppStorage("isMultiImageLayout") private var isMultiImageLayout = true
    @AppStorage("isImageBeforeText") private var isImageBeforeText = true

    var body: some View {
        NavigationStack {
            Form {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Section("iPad专属设置") {
                        Toggle("多栏详情视图", isOn: .constant(true))
                            .disabled(true)
                    }
                }

                Section("界面设置") {
                    Stepper("字体大小: \(Int(fontSize))", value: $fontSize, in: 12...24)
                    Toggle("触感反馈", isOn: $enableHaptic)
                    Toggle("多图叠加展示", isOn: $isMultiImageLayout)
                    Toggle("图片文前展示", isOn: $isImageBeforeText)
                }

                Section("功能设置") {
                    Toggle("关闭图片文字识别", isOn: $disableOCR)
                        .tint(.blue)
                }

                Section("数据管理") {
                    NavigationLink("备份与恢复") {
                        BackupView()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .padding(.horizontal, 8)
            )
            .padding(.top, 12)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground).opacity(0.2), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct BackupView: View {
    @Query(sort: \EmotionEntry.timestamp, order: .reverse) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var showImportAlert = false

    private var exportData: Data? {
        let transfers = entries.map { EmotionEntryTransfer(from: $0) }
        return try? JSONEncoder().encode(transfers)
    }

    var body: some View {
        List {
            Section {
                if let data = exportData {
                    ShareLink(item: data, preview: SharePreview("MemoGalaxy备份", image: Image(systemName: "doc.text"))) {
                        Label("导出全部日记 (JSON)", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label("暂无数据可导出", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("导出为JSON文件，可通过AirDrop、邮件等方式分享")
            }

            Section {
                Button {
                    showImporter = true
                } label: {
                    Label("导入日记备份", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("从JSON备份文件恢复日记，已存在的条目不会重复导入")
            }
        }
        .navigationTitle("备份与恢复")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard let data = try? Data(contentsOf: url) else {
                    importMessage = "文件读取失败"
                    showImportAlert = true
                    return
                }
                importFromJSON(data)
            case .failure(let error):
                importMessage = String(localized: "导入失败: \(error.localizedDescription)")
                showImportAlert = true
            }
        }
        .alert("导入结果", isPresented: $showImportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func importFromJSON(_ data: Data) {
        guard let transfers = try? JSONDecoder().decode([EmotionEntryTransfer].self, from: data) else {
            importMessage = "JSON解析失败"
            showImportAlert = true
            return
        }
        let existingIDs = Set(entries.map(\.id))
        var imported = 0
        for transfer in transfers where !existingIDs.contains(transfer.id) {
            let entry = transfer.toEntry()
            modelContext.insert(entry)
            imported += 1
        }
        importMessage = String(localized: "导入完成：新增\(imported)条日记")
        showImportAlert = true
    }
}

// MARK: - Transfer models for backup
struct EmotionEntryTransfer: Codable {
    let id: UUID
    let title: String
    let content: String
    let emotion: String
    let timestamp: Date
    let customColor: String?
    let customOpacity: Double
    let imageDataArray: [Data]?
    let comments: [DiaryCommentTransfer]

    init(from entry: EmotionEntry) {
        self.id = entry.id
        self.title = entry.title
        self.content = entry.content
        self.emotion = entry.emotion
        self.timestamp = entry.timestamp
        self.customColor = entry.customColor
        self.customOpacity = entry.customOpacity
        self.imageDataArray = entry.sortedImageData.isEmpty ? nil : entry.sortedImageData
        self.comments = entry.comments.map { DiaryCommentTransfer(from: $0) }
    }

    func toEntry() -> EmotionEntry {
        EmotionEntry(
            id: id,
            title: title,
            content: content,
            emotion: emotion,
            timestamp: timestamp,
            imageDataArray: imageDataArray,
            customColor: customColor,
            customOpacity: customOpacity
        )
    }
}

struct DiaryCommentTransfer: Codable {
    let id: UUID
    let content: String
    let timestamp: Date

    init(from comment: DiaryComment) {
        self.id = comment.id
        self.content = comment.content
        self.timestamp = comment.timestamp
    }
}
