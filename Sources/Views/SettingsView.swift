import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 设置页：备份与恢复、数据管理
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [InventoryItem]

    @State private var showClearConfirm = false
    @State private var showExporter = false
    @State private var exportDocument: BackupDocument?
    @State private var confirmApply = false
    @State private var pendingRestore: [InventoryItem] = []
    @State private var pendingCount = 0
    @State private var showMessage = false
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("数据统计")
                                .font(.system(size: 16, weight: .semibold))
                            statRow("物品总数", "\(items.count)")
                            statRow("需关注", "\(items.filter { $0.needsAttention }.count)")
                            statRow("尚未拆封", "\(items.filter { !$0.isOpened }.count)")
                        }
                        .padding(16)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("备份与恢复")
                                .font(.system(size: 16, weight: .semibold))
                            Button(action: prepareBackup) {
                                HStack {
                                    Text("备份数据")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                }
                            }
                            Divider().opacity(0.4)
                            // 原生文件选择器：从最顶层控制器直接弹出，避免嵌套模态选不中文件
                            Button(action: {
                                DocumentPicker.shared.present(
                                    onPicked: handlePicked,
                                    onCancel: {}
                                )
                            }) {
                                HStack {
                                    Text("恢复数据")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                    Spacer()
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                }
                            }
                            Text("备份导出为 JSON 文件；恢复会用备份内容替换当前全部数据。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                    // 选完文件并解码成功后再确认是否应用
                    .alert("确认恢复？", isPresented: $confirmApply) {
                        Button("取消", role: .cancel) { pendingRestore = [] }
                        Button("恢复", role: .destructive) { applyRestore() }
                    } message: {
                        Text("备份中共 \(pendingCount) 件物品，将替换当前全部数据（物品与记录）。")
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("数据管理")
                                .font(.system(size: 16, weight: .semibold))
                            Button {
                                showClearConfirm = true
                            } label: {
                                HStack {
                                    Text("清空全部数据")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .alert("确定清空全部数据？", isPresented: $showClearConfirm) {
                        Button("取消", role: .cancel) {}
                        Button("清空", role: .destructive) {
                            clearAll()
                        }
                    } message: {
                        Text("所有物品、拆封与补货记录将被永久删除，且不可恢复。")
                    }

                    Text("家庭库存管理 v1.0\n基于 Swift 6 · SwiftData · 液态玻璃设计")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                GlassTopBar(title: "设置")
            }
            .alert(messageText, isPresented: $showMessage) {
                Button("好", role: .cancel) {}
            }
        }
        .fileExporter(isPresented: $showExporter,
                      document: exportDocument,
                      contentType: .json,
                      defaultFilename: "HomeInventoryBackup") { result in
            switch result {
            case .success:
                messageText = "备份成功"
            case .failure(let error):
                messageText = "备份失败：\(error.localizedDescription)"
            }
            showMessage = true
        }
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
        }
    }

    private func prepareBackup() {
        do {
            let data = try BackupManager.encode(items: items)
            exportDocument = BackupDocument(data: data)
            showExporter = true
        } catch {
            messageText = "备份失败：\(error.localizedDescription)"
            showMessage = true
        }
    }

    /// 选择文件后：读取并解码（asCopy 已把文件复制进沙盒，无需安全作用域访问），成功后等用户确认
    private func handlePicked(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let restored = try BackupManager.decode(data)
            pendingRestore = restored
            pendingCount = restored.count
            confirmApply = true
        } catch {
            messageText = "恢复失败：\(error.localizedDescription)"
            showMessage = true
        }
    }

    /// 确认后应用恢复：先清空当前数据再写入备份，避免唯一主键冲突
    private func applyRestore() {
        for item in items { modelContext.delete(item) }
        try? modelContext.save()
        for item in pendingRestore { modelContext.insert(item) }
        try? modelContext.save()
        messageText = "恢复成功，共 \(pendingRestore.count) 件物品"
        pendingRestore = []
        showMessage = true
    }

    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
