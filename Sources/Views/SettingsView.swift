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
    @State private var showImporter = false
    @State private var confirmRestore = false
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
                            Button(action: { confirmRestore = true }) {
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
                    .alert("确定恢复？", isPresented: $confirmRestore) {
                        Button("取消", role: .cancel) {}
                        Button("恢复", role: .destructive) { showImporter = true }
                    } message: {
                        Text("将用所选备份文件替换当前全部物品与记录，且不可撤销。")
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
            // 用 .data 放宽可选文件类型：避免部分文件/目录被系统置灰无法选中；
            // 具体是不是本应用备份的 JSON，导入时由 BackupManager 解码校验
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [.data],
                          allowsMultipleSelection: false) { result in
                switch result {
                case .success(let url):
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        let restored = try BackupManager.decode(data)
                        // 先清空当前数据再写入备份，避免唯一主键冲突
                        for item in items { modelContext.delete(item) }
                        try modelContext.save()
                        for item in restored { modelContext.insert(item) }
                        try modelContext.save()
                        messageText = "恢复成功，共 \(restored.count) 件物品"
                    } catch {
                        messageText = "恢复失败：\(error.localizedDescription)"
                    }
                    showMessage = true
                case .failure(let error):
                    messageText = "选择文件失败：\(error.localizedDescription)"
                    showMessage = true
                }
            }
            .alert(messageText, isPresented: $showMessage) {
                Button("好", role: .cancel) {}
            }
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

    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
