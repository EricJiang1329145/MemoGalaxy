import SwiftUI

struct SettingsView: View {
    @AppStorage("enableHaptic") private var enableHaptic = true
    @AppStorage("fontSize") private var fontSize = 16.0
    // 新增两个存储选项
    @AppStorage("isMultiImageLayout") private var isMultiImageLayout = true
    @AppStorage("isImageBeforeText") private var isImageBeforeText = true
    
    var body: some View {
        NavigationStack {
            Form {
                ipadSpecificSettings()
                Section("界面设置") {
                    Stepper("字体大小: \(Int(fontSize))", value: $fontSize, in: 12...24)
                    Toggle("触感反馈", isOn: $enableHaptic)
                        .toggleStyle(.automatic)
                    
                    // 新增图片布局选项
                    Toggle("多图叠加展示", isOn: $isMultiImageLayout)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    
                    // 新增图片位置选项
                    Toggle("图片文前展示", isOn: $isImageBeforeText)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        // 通过环境变量获取presentationMode实现返回
                        dismiss()
                    }
                }
            }
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
    
    // 添加环境变量获取
    @Environment(\.dismiss) private var dismiss
    
    @ViewBuilder
    private func ipadSpecificSettings() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            Section("iPad专属设置") {
                Toggle("侧边栏模式", isOn: .constant(true))
                Toggle("分栏视图", isOn: .constant(true))
            }
            .listRowSeparatorTint(.accentColor)
        } else {
            EmptyView()
        }
    }
}

struct BackupView: View {
    var body: some View {
        Text("备份功能开发中")
            .foregroundStyle(.secondary)
    }
}


