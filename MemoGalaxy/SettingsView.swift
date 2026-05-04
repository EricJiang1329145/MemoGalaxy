import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("enableHaptic") private var enableHaptic = true
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("disableOCR") private var disableOCR = false
    @AppStorage("isMultiImageLayout") private var isMultiImageLayout = true
    @AppStorage("isImageBeforeText") private var isImageBeforeText = true
    @AppStorage("appLanguage") private var appLanguage = "system"
    @Environment(\.appLocale) private var locale: Locale

    var body: some View {
        NavigationStack {
            Form {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Section {
                        Toggle(localized("多栏详情视图"), isOn: .constant(true))
                            .disabled(true)
                    } header: {
                        Text(localized("iPad专属设置"))
                    }
                }

                Section {
                    Stepper(String(format: localized("字体大小: %lld"), Int(fontSize)), value: $fontSize, in: 12...24)
                    Toggle(localized("触感反馈"), isOn: $enableHaptic)
                    Toggle(localized("多图叠加展示"), isOn: $isMultiImageLayout)
                    Toggle(localized("图片文前展示"), isOn: $isImageBeforeText)

                    Picker(localized("语言"), selection: $appLanguage) {
                        Text("跟随系统").tag("system")
                        Text("简体中文").tag("zh-Hans")
                        Text("English").tag("en")
                    }
                } header: {
                    Text(localized("界面设置"))
                }

                Section {
                    Toggle(localized("关闭图片文字识别"), isOn: $disableOCR)
                        .tint(.blue)
                } header: {
                    Text(localized("功能设置"))
                }

                Section {
                    NavigationLink {
                        BackupView()
                    } label: {
                        Text(localized("备份与恢复"))
                    }
                } header: {
                    Text(localized("数据管理"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .padding(.horizontal, 8)
            )
            .padding(.top, 12)
            .navigationTitle(localized("设置"))
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

    private func localized(_ key: String) -> String {
        key.localized(locale: locale)
    }
}

struct BackupView: View {
    @Query(sort: \EmotionEntry.timestamp, order: .reverse) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appLocale) private var locale: Locale
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
                    ShareLink(item: data, preview: SharePreview(localized("MemoGalaxy备份"), image: Image(systemName: "doc.text"))) {
                        Label(localized("导出全部日记 (JSON)"), systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label(localized("暂无数据可导出"), systemImage: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(localized("导出为JSON文件，可通过AirDrop、邮件等方式分享"))
            }

            Section {
                Button {
                    showImporter = true
                } label: {
                    Label(localized("导入日记备份"), systemImage: "square.and.arrow.down")
                }
            } header: {
                Text(localized("从JSON备份文件恢复日记，已存在的条目不会重复导入"))
            }
        }
        .navigationTitle(localized("备份与恢复"))
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard let data = try? Data(contentsOf: url) else {
                    importMessage = localized("文件读取失败")
                    showImportAlert = true
                    return
                }
                importFromJSON(data)
            case .failure(let error):
                importMessage = String(format: localized("导入失败: %@"), error.localizedDescription)
                showImportAlert = true
            }
        }
        .alert(localized("导入结果"), isPresented: $showImportAlert) {
            Button(localized("确定"), role: .cancel) { }
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func importFromJSON(_ data: Data) {
        guard let transfers = try? JSONDecoder().decode([EmotionEntryTransfer].self, from: data) else {
            importMessage = localized("JSON解析失败")
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
        importMessage = String(format: localized("导入完成：新增%lld条日记"), imported)
        showImportAlert = true
    }

    private func localized(_ key: String) -> String {
        key.localized(locale: locale)
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

#Preview {
    SettingsView()
}