import SwiftUI
import SwiftData

/// 新增 / 编辑物品（二级页面）
/// 板块使用与设置页一致的液态玻璃卡片（GlassCard），标题在卡片内左上角；
/// 输入框保持简约浅灰圆角，胶囊分段选中纯绿底白字
/// 逻辑：
///  - 按剩余天数提醒 → 显示「使用历史消耗预测」+「平均消耗周期」
///  - 按库存数量提醒 → 隐藏消耗相关项
///  - 启用保质期 → 可选择「到期日期」或「保质期月数」两种记录方式
/// 存储位置候选：优先取已设置区域，其次历史位置；从区域页进入时自动预填该区域
struct ItemEditView: View {
    enum Mode {
        case add
        case edit(InventoryItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let mode: Mode

    // 查询全部物品，用于收集历史存放位置供选择复用
    @Query(sort: \InventoryItem.createdAt) private var allItems: [InventoryItem]
    // 已设置的区域（分区管理）
    @Query(sort: \InventoryArea.createdAt) private var areas: [InventoryArea]
    // 从区域页跳转添加时预填的存储位置
    @AppStorage("pendingAddLocation") private var pendingAddLocation = ""

    @State private var name = ""
    @State private var brand = ""
    @State private var category: Category = .paper
    @State private var location = ""
    @State private var totalStock = 1
    @State private var inUse = 0
    @State private var avgConsumeDays = 7
    @State private var reminderDays = 3
    @State private var reminderRule = 0          // 0=按剩余天数 1=按库存数量
    @State private var isOpened = true
    @AppStorage("useHistoryPrediction") private var useHistoryPrediction = true
    // 保质期
    @State private var enableExpiry = false
    @State private var expiryMode = 0            // 0=按到期日期 1=按保质期月数
    @State private var expiryDate = Date()
    @State private var shelfLifeMonths = 12

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // 板块一：消耗品信息
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardTitle("消耗品信息")
                            field("名称 *") { nameField }
                            field("品牌") { brandField }
                            field("分类 *") { categoryChips }
                        }
                        .padding(16)
                    }

                    // 板块二：库存与位置
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardTitle("库存与位置")
                            field("数量 *") { stockInput($totalStock) }
                            field("使用中") { stockInput($inUse) }
                            field("存储位置 *") {
                                VStack(alignment: .leading, spacing: 10) {
                                    locationField
                                    if !locationCandidates.isEmpty {
                                        locationChips
                                    }
                                }
                            }
                            toggleRow("已拆封", subtitle: "拆封后开始计算预计可用天数", isOn: $isOpened)
                        }
                        .padding(16)
                    }

                    // 板块三：消耗与提醒
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardTitle("消耗与提醒")
                            field("提醒规则") { reminderRulePicker }

                            // 仅「按剩余天数」需要消耗周期：显示历史消耗预测 + 平均消耗周期
                            if reminderRule == 0 {
                                toggleRow("使用历史消耗预测", subtitle: "未来根据使用情况自动优化周期", isOn: $useHistoryPrediction)
                                if useHistoryPrediction {
                                    Text("预测周期暂无·有预测数据后自动使用")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                field("平均消耗周期 *") { stockStepper("每件约 \(avgConsumeDays) 天", onDown: decrementAvg, onUp: incrementAvg) }
                            }

                            field("补货提醒 *") {
                                stockStepper(reminderRule == 0 ? "剩余 \(reminderDays) 天时提醒" : "库存 ≤ \(reminderDays) 件时提醒",
                                             onDown: decrementRemind, onUp: incrementRemind)
                            }
                        }
                        .padding(16)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: reminderRule)
                    }

                    // 板块四：保质期
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardTitle("保质期")
                            toggleRow("启用保质期", subtitle: "按每次拆封时间计算过期日期", isOn: $enableExpiry)
                            if enableExpiry {
                                field("计算方式") { expiryModePicker }
                                if expiryMode == 0 {
                                    field("到期日期 *") { expiryDateField }
                                } else {
                                    field("保质期月数 *") { stockStepper("\(shelfLifeMonths) 个月", onDown: decrementMonths, onUp: incrementMonths) }
                                }
                            }
                        }
                        .padding(16)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: enableExpiry)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: expiryMode)
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                GlassTopBar(
                    title: isEditing ? "编辑物品" : "添加物品",
                    leading: { GlassCircleButton(icon: "chevron.left") { dismiss() } },
                    trailing: {
                        Button(action: save) {
                            Text(isEditing ? "保存" : "添加")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .glassEffect(.regular.tint(Color(red: 0.36, green: 0.62, blue: 0.48)), in: .capsule)
                        }
                    }
                )
            }
        }
        .onAppear(perform: load)
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - 样式

    /// 卡片内标题（与设置页「数据统计/区域管理」同款）
    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
    }

    /// 简约浅灰圆角输入容器（白底上轻微灰底，无描边）
    private var inputBg: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(uiColor: UIColor { t in
                t.userInterfaceStyle == .dark
                    ? UIColor(white: 0.18, alpha: 1)
                    : UIColor(red: 0.95, green: 0.955, blue: 0.95, alpha: 1)
            }))
    }

    /// 胶囊未选中底色（浅色=浅灰，深色=深灰）
    private var chipBg: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(white: 0.20, alpha: 1) : UIColor(red: 0.95, green: 0.955, blue: 0.95, alpha: 1)
        })
    }

    private func field(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            content()
        }
    }

    /// 开关行：左文字右开关，无背景框
    private func toggleRow(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(red: 0.36, green: 0.62, blue: 0.48))
        }
        .padding(.vertical, 2)
    }

    private func load() {
        if case .edit(let item) = mode {
            name = item.name
            brand = item.brand
            category = item.category
            location = item.location
            totalStock = item.totalStock
            inUse = item.inUse
            avgConsumeDays = item.avgConsumeDays
            reminderDays = item.reminderDays
            reminderRule = item.reminderRule
            isOpened = item.isOpened
            enableExpiry = item.expiryEnabled
            expiryMode = item.expiryMode
            expiryDate = item.expiryDate ?? Date()
            shelfLifeMonths = max(1, item.shelfLifeMonths)
        } else {
            // 从区域页「去添加」进入：预填该区域，并消费掉临时标记
            location = pendingAddLocation
            pendingAddLocation = ""
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if case .edit(let item) = mode {
            item.name = trimmed
            item.brand = brand.trimmingCharacters(in: .whitespaces)
            item.category = category
            item.location = location.isEmpty ? "未指定" : location
            item.totalStock = max(0, totalStock)
            item.inUse = max(0, inUse)
            item.avgConsumeDays = max(1, avgConsumeDays)
            item.reminderDays = max(1, reminderDays)
            item.reminderRule = reminderRule
            item.isOpened = isOpened
            if isOpened { item.lastUnpackDate = item.lastUnpackDate ?? Date() }
            item.expiryEnabled = enableExpiry
            item.expiryMode = expiryMode
            item.expiryDate = enableExpiry && expiryMode == 0 ? expiryDate : nil
            item.shelfLifeMonths = max(1, shelfLifeMonths)
        } else {
            let item = InventoryItem(
                name: trimmed,
                brand: brand.trimmingCharacters(in: .whitespaces),
                category: category,
                location: location.isEmpty ? "未指定" : location,
                totalStock: max(0, totalStock),
                inUse: max(0, inUse),
                avgConsumeDays: max(1, avgConsumeDays),
                reminderDays: max(1, reminderDays),
                reminderRule: reminderRule,
                isOpened: isOpened,
                expiryEnabled: enableExpiry,
                expiryMode: expiryMode,
                expiryDate: enableExpiry && expiryMode == 0 ? expiryDate : nil,
                shelfLifeMonths: max(1, shelfLifeMonths)
            )
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }

    // MARK: - 输入控件

    private var nameField: some View {
        TextField("请输入名称", text: $name)
            .font(.system(size: 15))
            .padding(14)
            .background(inputBg)
    }

    private var brandField: some View {
        TextField("例如：维达", text: $brand)
            .font(.system(size: 15))
            .padding(14)
            .background(inputBg)
    }

    /// 分类标签选择：流式换行布局（避免 LazyVGrid 高频切换崩溃），未选中浅灰底，选中纯绿底白字
    private var categoryChips: some View {
        FlowLayout(spacing: 10) {
            ForEach(Category.allCases) { c in
                Button { category = c } label: {
                    Text(c.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(category == c ? .white : Color(red: 0.28, green: 0.52, blue: 0.40))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(category == c ? Color(red: 0.36, green: 0.62, blue: 0.48) : chipBg))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: category)
    }

    /// 提醒规则：纯色胶囊分段切换
    private var reminderRulePicker: some View {
        HStack(spacing: 4) {
            segmentCapsule("按剩余天数", selected: reminderRule == 0) { reminderRule = 0 }
            segmentCapsule("按库存数量", selected: reminderRule == 1) { reminderRule = 1 }
        }
        .padding(4)
        .background(Capsule().fill(chipBg))
    }

    /// 保质期计算方式：按到期日期 / 按保质期月数
    private var expiryModePicker: some View {
        HStack(spacing: 4) {
            segmentCapsule("按到期日期", selected: expiryMode == 0) { expiryMode = 0 }
            segmentCapsule("按保质期月数", selected: expiryMode == 1) { expiryMode = 1 }
        }
        .padding(4)
        .background(Capsule().fill(chipBg))
    }

    private func segmentCapsule(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(selected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? Color(red: 0.36, green: 0.62, blue: 0.48) : Color.clear))
        }
    }

    private var locationField: some View {
        TextField("请输入存放位置", text: $location)
            .font(.system(size: 15))
            .foregroundColor(location.isEmpty ? .secondary : .primary)
            .padding(14)
            .background(inputBg)
    }

    /// 位置候选：已设置区域优先，其次历史使用过的位置（去重）
    private var locationCandidates: [String] {
        var set = Set<String>()
        for a in areas { set.insert(a.name) }
        for loc in allItems.map(\.location) {
            if !loc.isEmpty && loc != "未指定" { set.insert(loc) }
        }
        return set.sorted()
    }

    /// 位置候选胶囊：流式换行，点击即填入
    private var locationChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(locationCandidates, id: \.self) { loc in
                Button { location = loc } label: {
                    Text(loc)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(location == loc ? .white : Color(red: 0.28, green: 0.52, blue: 0.40))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(location == loc ? Color(red: 0.36, green: 0.62, blue: 0.48) : chipBg))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: location)
    }

    /// 到期日期选择（compact 日期选择器）
    private var expiryDateField: some View {
        DatePicker("", selection: $expiryDate, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Color(red: 0.36, green: 0.62, blue: 0.48))
            .padding(12)
            .background(inputBg)
    }

    /// 数量输入：可手动输入数字（数字键盘），也保留 +/- 步进按钮
    private func stockInput(_ value: Binding<Int>) -> some View {
        HStack(spacing: 10) {
            TextField("0", text: Binding(
                get: { "\(value.wrappedValue)" },
                set: { newValue in
                    // 只保留数字字符，空输入视为 0
                    let digits = newValue.filter(\.isNumber)
                    value.wrappedValue = Int(digits) ?? 0
                }
            ))
            .keyboardType(.numberPad)
            .font(.system(size: 15, weight: .medium))
            Text("件")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Button { if value.wrappedValue > 0 { value.wrappedValue -= 1 } } label: { stepIcon("minus") }
            Button { value.wrappedValue += 1 } label: { stepIcon("plus") }
        }
        .padding(10)
        .background(inputBg)
    }

    private func stockStepper(_ valueText: String, onDown: @escaping () -> Void, onUp: @escaping () -> Void) -> some View {
        HStack {
            Text(valueText)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Button(action: onDown) { stepIcon("minus") }
            Button(action: onUp) { stepIcon("plus") }
        }
        .padding(10)
        .background(inputBg)
    }

    private func stepIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color(red: 0.30, green: 0.55, blue: 0.42))
            .frame(width: 34, height: 34)
            .background(Circle().fill(Color(red: 0.36, green: 0.62, blue: 0.48).opacity(0.15)))
    }

    private func incrementAvg() { avgConsumeDays += 1 }
    private func decrementAvg() { if avgConsumeDays > 1 { avgConsumeDays -= 1 } }
    private func incrementRemind() { reminderDays += 1 }
    private func decrementRemind() { if reminderDays > 1 { reminderDays -= 1 } }
    private func incrementMonths() { shelfLifeMonths += 1 }
    private func decrementMonths() { if shelfLifeMonths > 1 { shelfLifeMonths -= 1 } }
}

/// 轻量流式换行布局：子视图按宽度自动换行（替代 LazyVGrid，高频状态切换更稳定）
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
