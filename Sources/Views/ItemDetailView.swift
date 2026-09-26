import SwiftUI
import SwiftData

/// 物品详情页：库存信息、拆封/补货、消耗预测、消耗与提醒
struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: InventoryItem

    // 查询全部物品，用于收集历史存放位置供选择复用
    @Query(sort: \InventoryItem.createdAt) private var allItems: [InventoryItem]

    @State private var showEdit = false
    @State private var showUnpack = false
    @State private var showRestock = false
    @State private var showCustomLocation = false
    @State private var customLocation = ""

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    infoCard
                    actionButtons
                    predictionCard
                    reminderCard
                    recordsCard
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                GlassTopBar(
                    title: item.name,
                    leading: { GlassCircleButton(icon: "chevron.left") { dismiss() } },
                    trailing: { GlassCircleButton(icon: "pencil", tint: Color(red: 0.36, green: 0.62, blue: 0.48)) { showEdit = true } }
                )
            }
            .sheet(isPresented: $showEdit) {
                ItemEditView(mode: .edit(item))
            }
            .sheet(isPresented: $showUnpack) {
                UnpackSheet(item: item)
            }
            .sheet(isPresented: $showRestock) {
                RestockSheet(item: item)
            }
            .alert("修改存放位置", isPresented: $showCustomLocation) {
                TextField("输入新位置", text: $customLocation)
                Button("确定") {
                    setLocation(customLocation)
                    customLocation = ""
                }
                Button("取消", role: .cancel) { customLocation = "" }
            }
        }
    }

    // MARK: - 基本信息

    private var infoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(item.category.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(item.totalStock)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                    Text("库存")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Divider().opacity(0.4)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("存放位置")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        locationControl
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("最近拆封")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        if let rec = item.lastUnpackRecord {
                            Text("\(Format.shortDate(rec.date))·\(Format.relativeDays(from: rec.date))·\(rec.quantity)包")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        } else {
                            Text("暂无记录")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func labelBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    /// 存放位置修改入口：弹出历史已用位置供选择 + 自定义输入（自定义过的位置自动进入候选）
    private var locationControl: some View {
        Menu {
            ForEach(usedLocations, id: \.self) { r in
                Button { setLocation(r) } label: {
                    if item.location == r { Label(r, systemImage: "checkmark") }
                    else { Text(r) }
                }
            }
            Button { showCustomLocation = true } label: {
                Label("自定义位置…", systemImage: "pencil")
            }
        } label: {
            HStack(spacing: 6) {
                Text(item.location)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.36, green: 0.62, blue: 0.48))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(.clear, in: .capsule)
        }
    }

    /// 历史存放位置（数据库去重，自定义过即出现在候选里）
    private var usedLocations: [String] {
        Set(allItems.map { $0.location })
            .filter { !$0.isEmpty && $0 != "未指定" }
            .sorted()
    }

    private func setLocation(_ new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        item.location = trimmed
        try? modelContext.save()
    }

    // MARK: - 拆封 / 补货按钮

    private var actionButtons: some View {
        HStack(spacing: 14) {
            GlassCapsuleButton(title: "拆封", tint: Color(red: 0.36, green: 0.62, blue: 0.48)) {
                showUnpack = true
            }
            GlassCapsuleButton(title: "补货", tint: Color(red: 0.45, green: 0.58, blue: 0.33)) {
                showRestock = true
            }
        }
    }

    // MARK: - 消耗预测

    private var predictionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("消耗预测")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("基于30天预测窗口")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .lastTextBaseline) {
                    Text("预计\(item.remainingDays)天后耗尽")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                    Spacer()
                    StatusCapsule(text: item.status.title, color: item.needsAttention ? .orange : Color(red: 0.36, green: 0.62, blue: 0.48))
                }

                HStack {
                    Text("今天·剩余\(item.totalStock)包，预计\(item.remainingDays)天后耗尽")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("\(Format.shortDate(item.exhaustionDate))·预计用完当前库存")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
    }

    // MARK: - 消耗与提醒

    private var reminderCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("消耗与提醒")
                    .font(.system(size: 16, weight: .semibold))
                Divider().opacity(0.4)
                row("提醒依据", value: "按剩余天数")
                row("平均消耗", value: "\(item.avgConsumeDays)天")
                row("提醒规则", value: "剩余≤\(item.reminderDays)天")
            }
            .padding(16)
        }
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    // MARK: - 记录

    private var recordsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("记录")
                    .font(.system(size: 16, weight: .semibold))
                if item.unpackRecords.isEmpty && item.restockRecords.isEmpty {
                    Text("暂无记录")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                } else {
                    ForEach(combinedRecords) { line in
                        HStack {
                            Text(line.text)
                                .font(.system(size: 13))
                            Spacer()
                            Text(line.dateText)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    /// 合并后的记录行（拆封 + 补货，按时间倒序）
    private struct RecordRow: Identifiable {
        let id: UUID
        let text: String
        let dateText: String
        let date: Date
    }

    private var combinedRecords: [RecordRow] {
        var rows: [RecordRow] = []
        for rec in item.unpackRecords {
            rows.append(RecordRow(id: rec.id, text: "拆封 \(rec.quantity)包", dateText: Format.shortDate(rec.date), date: rec.date))
        }
        for rec in item.restockRecords {
            rows.append(RecordRow(id: rec.id, text: "补货 \(rec.quantity)包", dateText: Format.shortDate(rec.date), date: rec.date))
        }
        return rows.sorted { $0.date > $1.date }
    }
}

/// 拆封弹窗
struct UnpackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: InventoryItem
    @State private var quantity = 1

    var body: some View {
        sheetBody(title: "拆封", tint: Color(red: 0.36, green: 0.62, blue: 0.48)) {
            item.unpack(quantity: quantity)
            let rec = UnpackRecord(quantity: quantity)
            rec.item = item
            modelContext.insert(rec)
            try? modelContext.save()
            dismiss()
        }
    }

    @ViewBuilder
    private func sheetBody(title: String, tint: Color, confirm: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 8)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            Text("当前库存 \(item.totalStock) 件")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            stepper
            GlassCapsuleButton(title: "确认", tint: tint, action: confirm)
            Spacer()
        }
        .padding(20)
        .presentationDetents([.height(260)])
    }

    private var stepper: some View {
        HStack(spacing: 16) {
            Button { if quantity > 1 { quantity -= 1 } } label: { circle("-") }
            Text("\(quantity)")
                .font(.system(size: 26, weight: .bold))
                .frame(width: 60)
            Button { quantity += 1 } label: { circle("+") }
        }
    }

    private func circle(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
    }
}

/// 补货弹窗
struct RestockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: InventoryItem
    @State private var quantity = 1

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 8)
            Text("补货")
                .font(.system(size: 18, weight: .semibold))
            Text("当前库存 \(item.totalStock) 件")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                Button { if quantity > 1 { quantity -= 1 } } label: { circle("-") }
                Text("\(quantity)")
                    .font(.system(size: 26, weight: .bold))
                    .frame(width: 60)
                Button { quantity += 1 } label: { circle("+") }
            }
            GlassCapsuleButton(title: "确认", tint: Color(red: 0.45, green: 0.58, blue: 0.33)) {
                item.restock(quantity: quantity)
                let rec = RestockRecord(quantity: quantity)
                rec.item = item
                modelContext.insert(rec)
                try? modelContext.save()
                dismiss()
            }
            Spacer()
        }
        .padding(20)
        .presentationDetents([.height(260)])
    }

    private func circle(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color(red: 0.55, green: 0.65, blue: 0.48)))
    }
}
