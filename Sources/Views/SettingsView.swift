import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 设置页：区域管理（可排序）、备份与恢复、数据管理
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [InventoryItem]
    @Query(sort: \InventoryArea.sortOrder) private var areas: [InventoryArea]

    @State private var showClearConfirm = false
    @State private var showExporter = false
    @State private var exportDocument: BackupDocument?
    @State private var backupFilename = "HomeInventoryBackup"
    @State private var showHome = false
    @State private var confirmApply = false
    @State private var pendingRestore: [InventoryItem] = []
    @State private var pendingAreas: [AreaDTO] = []
    @State private var pendingCount = 0
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var showAddArea = false
    @State private var newAreaName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 数据统计：点击进入主页内容
                    Button {
                        showHome = true
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("数据统计")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                statRow("物品总数", "\(items.count)")
                                statRow("需关注", "\(items.filter { $0.needsAttention }.count)")
                                statRow("尚未拆封", "\(items.filter { !$0.isOpened }.count)")
                            }
                            .padding(16)
                        }
                    }
                    .buttonStyle(.plain)

                    // 区域管理：添加区域后底部导航出现对应分区入口；↑↓ 可调整顺序
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("区域管理")
                                .font(.system(size: 16, weight: .semibold))
                            Text("添加区域后，底部导航会显示该区域的库存管理入口；第一个区域为默认进入页，可用 ↑↓ 调整顺序。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            if areas.isEmpty {
                                HStack {
                                    Image(systemName: "location")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text("还没有区域")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            } else {
                                ForEach(areas) { area in
                                    HStack(spacing: 10) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                        Text(area.name)
                                            .font(.system(size: 15, weight: .medium))
                                        Spacer()
                                        Text("\(items.filter { $0.location == area.name }.count) 件")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        // 上移
                                        Button {
                                            moveArea(area, offset: -1)
                                        } label: {
                                            Image(systemName: "chevron.up")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(areas.first?.id == area.id ? Color.gray.opacity(0.3) : Color(red: 0.36, green: 0.62, blue: 0.48))
                                        }
                                        .disabled(areas.first?.id == area.id)
                                        // 下移
                                        Button {
                                            moveArea(area, offset: 1)
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(areas.last?.id == area.id ? Color.gray.opacity(0.3) : Color(red: 0.36, green: 0.62, blue: 0.48))
                                        }
                                        .disabled(areas.last?.id == area.id)
                                        Button {
                                            deleteArea(area)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            Divider().opacity(0.4)
                            Button {
                                showAddArea = true
                            } label: {
                                HStack {
                                    Text("添加区域")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                    Spacer()
                                    Image(systemName: "plus")
                                        .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
                                }
                            }
                        }
                        .padding(16)
                    }
                    .alert("添加区域", isPresented: $showAddArea) {
                        TextField("区域名称，如：东阳", text: $newAreaName)
                        Button("添加") { addArea() }
                        Button("取消", role: .cancel) { newAreaName = "" }
                    } message: {
                        Text("添加后底部导航会出现该区域的库存管理入口，并自动设为默认进入页。")
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
                        }
                        .padding(16)
                    }
                    // 选完文件并解码成功后再确认是否应用
                    .alert("确认恢复？", isPresented: $confirmApply) {
                        Button("取消", role: .cancel) { pendingRestore = [] }
                        Button("恢复", role: .destructive) { applyRestore() }
                    } message: {
                        Text("备份中共 \(pendingCount) 件物品、\(pendingAreas.count) 个区域，将替换当前全部数据（物品与记录）。")
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
                        Text("所有物品、区域、拆封与补货记录将被永久删除，且不可恢复。")
                    }

                    Text("家庭库存管理 v1.0\n基于 Swift 6 \n黑子 ")
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
            // 数据统计 → 主页内容
            .navigationDestination(isPresented: $showHome) {
                HomeView()
            }
            .alert(messageText, isPresented: $showMessage) {
                Button("好", role: .cancel) {}
            }
        }
        .fileExporter(isPresented: $showExporter,
                      document: exportDocument,
                      contentType: .json,
                      defaultFilename: backupFilename) { result in
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

    // MARK: - 区域管理

    private func addArea() {
        let trimmed = newAreaName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !areas.contains(where: { $0.name == trimmed }) {
            let nextOrder = (areas.map(\.sortOrder).max() ?? -1) + 1
            modelContext.insert(InventoryArea(name: trimmed, sortOrder: nextOrder))
            try? modelContext.save()
        }
        newAreaName = ""
    }

    private func deleteArea(_ area: InventoryArea) {
        modelContext.delete(area)
        try? modelContext.save()
    }

    /// 上移/下移：交换相邻两个区域的 sortOrder，底部导航顺序随之变化
    private func moveArea(_ area: InventoryArea, offset: Int) {
        guard let idx = areas.firstIndex(where: { $0.id == area.id }) else { return }
        let target = idx + offset
        guard areas.indices.contains(target) else { return }
        let other = areas[target]
        let tmp = area.sortOrder
        area.sortOrder = other.sortOrder
        other.sortOrder = tmp
        try? modelContext.save()
    }

    // MARK: - 备份 / 恢复

    /// 备份文件名带当前日期时间，便于区分多次备份
    private func prepareBackup() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        backupFilename = "HomeInventoryBackup_\(formatter.string(from: Date()))"
        do {
            let data = try BackupManager.encode(items: items, areas: areas)
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
            let result = try BackupManager.decode(data)
            pendingRestore = result.items
            pendingAreas = result.areas
            pendingCount = result.items.count
            confirmApply = true
        } catch {
            messageText = "恢复失败：\(error.localizedDescription)"
            showMessage = true
        }
    }

    /// 确认后应用恢复：先清空当前数据再写入备份，避免唯一主键冲突
    private func applyRestore() {
        for item in items { modelContext.delete(item) }
        for area in areas { modelContext.delete(area) }
        try? modelContext.save()
        for areaDTO in pendingAreas {
            modelContext.insert(InventoryArea(name: areaDTO.name, sortOrder: areaDTO.sortOrder))
        }
        for item in pendingRestore { modelContext.insert(item) }
        try? modelContext.save()
        messageText = "恢复成功，共 \(pendingRestore.count) 件物品、\(pendingAreas.count) 个区域"
        pendingRestore = []
        pendingAreas = []
        showMessage = true
    }

    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
        for area in areas {
            modelContext.delete(area)
        }
        try? modelContext.save()
    }
}
