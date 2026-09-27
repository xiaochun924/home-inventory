import SwiftUI
import SwiftData

/// 新增 / 编辑物品（二级页面）
/// 布局参考「有余」：顶部返回 + 保存，正文按板块分块（消耗品信息 / 库存与位置 / 消耗与提醒 / 保质期 / 补货）
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

    @State private var name = ""
    @State private var brand = ""
    @State private var category: Category = .paper
    @State private var location = ""
    @State private var totalStock = 1
    @State private var inUse = 0
    @State private var avgConsumeDays = 7
    @State private var reminderDays = 3
    @State private var isOpened = true
    @State private var reminderRule = 0          // 0=按剩余天数 1=按库存数量
    @AppStorage("useHistoryPrediction") private var useHistoryPrediction = true
    @State private var enableExpiry = false

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    // 板块一：消耗品信息
                    sectionHeader("消耗品信息")
                    VStack(spacing: 14) {
                        field("名称 *") { nameField }
                        field("品牌") { brandField }
                        field("分类 *") { categoryChips }
                    }

                    // 板块二：库存与位置
                    sectionHeader("库存与位置")
                    VStack(spacing: 14) {
                        field("数量 *") { stockInput($totalStock) }
                        field("使用中") { stockInput($inUse) }
                        field("存储位置 *") {
                            VStack(alignment: .leading, spacing: 10) {
                                locationField
                                if !usedLocations.isEmpty {
                                    usedLocationChips
                                }
                            }
                        }
                        Toggle(isOn: $isOpened) {
                            Text("已拆封")
                                .font(.system(size: 15))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(glassBg)
                    }

                    // 板块三：消耗与提醒
                    sectionHeader("消耗与提醒")
                    VStack(spacing: 14) {
                        Picker("提醒规则", selection: $reminderRule) {
                            Text("按剩余天数").tag(0)
                            Text("按库存数量").tag(1)
                        }
                        .pickerStyle(.segmented)

                        Toggle(isOn: $useHistoryPrediction) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("使用历史消耗预测")
                                    .font(.system(size: 15))
                                Text("未来根据使用情况自动优化周期")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(glassBg)
                        if useHistoryPrediction {
                            Text("预测周期暂无·有预测数据后自动使用")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        field("平均消耗周期 *") { stockStepper("每件约 \(avgConsumeDays) 天", onDown: decrementAvg, onUp: incrementAvg) }
                        field(reminderRule == 0 ? "补货提醒 *" : "补货提醒 *") {
                            stockStepper(reminderRule == 0 ? "剩余 \(reminderDays) 天时提醒" : "库存 ≤ \(reminderDays) 件时提醒",
                                         onDown: decrementRemind, onUp: incrementRemind)
                        }
                    }

                    // 板块四：保质期
                    sectionHeader("保质期")
                    VStack(spacing: 8) {
                        Toggle(isOn: $enableExpiry) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("启用保质期")
                                    .font(.system(size: 15))
                                Text("按每次拆封时间计算过期日期")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(glassBg)
                    }

                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
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
                                .glassEffect(.regular.tint(Color(red: 0.36, green: 0.62, blue: 0.48)).interactive(), in: .capsule)
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

    private var glassBg: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.adaptiveCardFill)
            .background(RoundedRectangle(cornerRadius: 16).stroke(Color.adaptiveCardStroke, lineWidth: 1))
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
            isOpened = item.isOpened
        } else {
            location = ""
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
            item.isOpened = isOpened
            if isOpened { item.lastUnpackDate = item.lastUnpackDate ?? Date() }
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
                isOpened: isOpened
            )
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }

    // MARK: - 子控件

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.adaptiveTextGreen)
            Spacer()
        }
        .padding(.top, 6)
    }

    private func field(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            content()
        }
    }

    private var nameField: some View {
        TextField("请输入名称", text: $name)
            .font(.system(size: 15))
            .padding(14)
            .background(glassBg)
    }

    private var brandField: some View {
        TextField("例如：维达", text: $brand)
            .font(.system(size: 15))
            .padding(14)
            .background(glassBg)
    }

    /// 分类标签选择（参考截图横向胶囊）
    private var categoryChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 10) {
            ForEach(Category.allCases) { c in
                Button { category = c } label: {
                    Text(c.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(category == c ? .white : Color(red: 0.28, green: 0.52, blue: 0.40))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(category == c ? Color(red: 0.36, green: 0.62, blue: 0.48) : Color.clear))
                        .overlay(Capsule().stroke(category == c ? Color.clear : Color(red: 0.36, green: 0.62, blue: 0.48).opacity(0.4), lineWidth: 1))
                }
            }
        }
    }

    private var locationField: some View {
        TextField("请输入存放位置", text: $location)
            .font(.system(size: 15))
            .foregroundColor(location.isEmpty ? .secondary : .primary)
            .padding(14)
            .background(glassBg)
    }

    /// 历史存放位置（数据库去重，自定义过即出现在候选里）
    private var usedLocations: [String] {
        Set(allItems.map { $0.location })
            .filter { !$0.isEmpty && $0 != "未指定" }
            .sorted()
    }

    /// 历史位置候选胶囊：点击即填入
    private var usedLocationChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
            ForEach(usedLocations, id: \.self) { loc in
                Button { location = loc } label: {
                    Text(loc)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(location == loc ? .white : Color(red: 0.28, green: 0.52, blue: 0.40))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(location == loc ? Color(red: 0.36, green: 0.62, blue: 0.48) : Color.clear))
                        .overlay(Capsule().stroke(location == loc ? Color.clear : Color(red: 0.36, green: 0.62, blue: 0.48).opacity(0.4), lineWidth: 1))
                }
            }
        }
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
        .background(glassBg)
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
        .background(glassBg)
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
}
