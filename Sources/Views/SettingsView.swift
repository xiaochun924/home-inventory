import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 设置页：数据统计、区域管理（可排序）、备份与恢复、数据管理
/// 骨架对齐 BatteryInsight：系统 List + Section 分组，行用「图标方框 + 标题 + 数值」系统行
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
            List {
                // 数据统计：点击进入主页内容
                Section {
                    statRow(icon: "shippingbox.fill", tint: .green, title: "物品总数",
                            value: "\(items.count)", action: { showHome = true })
                    statRow(icon: "exclamationmark.circle.fill", tint: .orange, title: "需关注",
                            value: "\(items.filter { $0.needsAttention }.count)", action: { showHome = true })
                    statRow(icon: "shippingbox", tint: .gray, title: "尚未拆封",
                            value: "\(items.filter { !$0.isOpened }.count)", action: { showHome = true })
                } header: {
                    HStack {
                        Text("数据统计")
                        Spacer()
                        Button { showHome = true } label: {
                            Label("查看", systemImage: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 区域管理：添加区域后底部导航出现对应分区入口；↑↓ 可调整顺序
                Section {
                    if areas.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "location")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 26, height: 26)
                                .background(.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                            Text("还没有区域")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 1)
                    } else {
                        ForEach(areas) { area in
                            areaRow(area)
                        }
                    }
                    Button { showAddArea = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.36, green: 0.62, blue: 0.48))
                                .frame(width: 26, height: 26)
                                .background(Color(red: 0.36, green: 0.62, blue: 0.48).opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                            Text("添加区域")
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.36, green: 0.62, blue: 0.48))
                        }
                        .padding(.vertical, 1)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("区域管理")
                } footer: {
                    Text("添加区域后，底部导航会显示该区域的库存管理入口；第一个区域为默认进入页，可用 ↑↓ 调整顺序。")
                }
                .alert("添加区域", isPresented: $showAddArea) {
                    TextField("区域名称，如：东阳", text: $newAreaName)
                    Button("添加") { addArea() }
                    Button("取消", role: .cancel) { newAreaName = "" }
                } message: {
                    Text("添加后底部导航会出现该区域的库存管理入口，并自动设为默认进入页。")
                }

                // 备份与恢复
                Section {
                    Button(action: prepareBackup) {
                        row(icon: "square.and.arrow.up", tint: .green, title: "备份数据")
                    }
                    .buttonStyle(.plain)
                    // 原生文件选择器：从最顶层控制器直接弹出，避免嵌套模态选不中文件
                    Button(action: {
                        DocumentPicker.shared.present(
                            onPicked: handlePicked,
                            onCancel: {}
                        )
                    }) {
                        row(icon: "square.and.arrow.down", tint: .green, title: "恢复数据")
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("备份与恢复")
                }
                // 选完文件并解码成功后再确认是否应用
                .alert("确认恢复？", isPresented: $confirmApply) {
                    Button("取消", role: .cancel) { pendingRestore = [] }
                    Button("恢复", role: .destructive) { applyRestore() }
                } message: {
                    Text("备份中共 \(pendingCount) 件物品、\(pendingAreas.count) 个区域，将替换当前全部数据（物品与记录）。")
                }

                // 数据管理
                Section {
                    Button {
                        showClearConfirm = true
                    } label: {
                        row(icon: "trash", tint: .red, title: "清空全部数据")
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("数据管理")
                }
                .alert("确定清空全部数据？", isPresented: $showClearConfirm) {
                    Button("取消", role: .cancel) {}
                    Button("清空", role: .destructive) {
                        clearAll()
                    }
                } message: {
                    Text("所有物品、区域、拆封与补货记录将被永久删除，且不可恢复。")
                }

                Section {
                    Text("家庭库存管理 v1.0\n黑子 ")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .scrollIndicators(.hidden)
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

    // MARK: - 行组件（BatteryInsight 图标方框行）

    private func statRow(icon: String, tint: Color, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 1)
        }
        .buttonStyle(.plain)
    }

    private func row(icon: String, tint: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 1)
    }

    // MARK: - 区域管理行

    private func areaRow(_ area: InventoryArea) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "location.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.36, green: 0.62, blue: 0.48))
                .frame(width: 26, height: 26)
                .background(Color(red: 0.36, green: 0.62, blue: 0.48).opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
            Text(area.name)
                .font(.subheadline)
            Spacer()
            Text("\(items.filter { $0.location == area.name }.count) 件")
                .font(.caption)
                .foregroundStyle(.secondary)
            // 上移
            Button {
                moveArea(area, offset: -1)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(areas.first?.id == area.id ? .gray.opacity(0.3) : Color(red: 0.36, green: 0.62, blue: 0.48))
                    .frame(width: 24, height: 24)
                    .background(.quaternary, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(areas.first?.id == area.id)
            // 下移
            Button {
                moveArea(area, offset: 1)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(areas.last?.id == area.id ? .gray.opacity(0.3) : Color(red: 0.36, green: 0.62, blue: 0.48))
                    .frame(width: 24, height: 24)
                    .background(.quaternary, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(areas.last?.id == area.id)
            // 删除
            Button {
                deleteArea(area)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.red.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 1)
    }

    // MARK: - 区域管理逻辑

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
