import SwiftUI
import SwiftData

/// 新增 / 编辑物品
struct ItemEditView: View {
    enum Mode {
        case add
        case edit(InventoryItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let mode: Mode

    @State private var name = ""
    @State private var category: Category = .paper
    @State private var location = ""
    @State private var totalStock = 1
    @State private var inUse = 0
    @State private var avgConsumeDays = 5
    @State private var reminderDays = 3
    @State private var isOpened = true

    private let rooms = ["诸暨·1", "诸暨·2", "东阳·1", "东阳·2", "厨房", "卫生间"]

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    field("名称") { nameField }
                    field("品类") { categoryPicker }
                    field("存放位置") { roomPicker }
                    field("库存数量") { stockStepper("\(totalStock) 件", onDown: decrementStock, onUp: incrementStock) }
                    field("使用中") { stockStepper("\(inUse) 件", onDown: decrementInUse, onUp: incrementInUse) }
                    field("平均消耗（天/件）") { stockStepper("\(avgConsumeDays) 天", onDown: decrementAvg, onUp: incrementAvg) }
                    field("提醒规则（剩余≤X天）") { stockStepper("≤\(reminderDays) 天", onDown: decrementRemind, onUp: incrementRemind) }

                    Toggle(isOn: $isOpened) {
                        Text("已拆封")
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(glassBg)

                    GlassCapsuleButton(title: isEditing ? "保存修改" : "添加物品") {
                        save()
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
                    leading: { GlassCircleButton(icon: "xmark") { dismiss() } }
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
            .fill(.white.opacity(0.42))
            .background(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6), lineWidth: 1))
    }

    private func load() {
        if case .edit(let item) = mode {
            name = item.name
            category = item.category
            location = item.location
            totalStock = item.totalStock
            inUse = item.inUse
            avgConsumeDays = item.avgConsumeDays
            reminderDays = item.reminderDays
            isOpened = item.isOpened
        } else {
            location = rooms.first ?? "诸暨·1"
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if case .edit(let item) = mode {
            item.name = trimmed
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

    private func field(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            content()
        }
    }

    private var nameField: some View {
        TextField("例如：尿不湿 M", text: $name)
            .font(.system(size: 15))
            .padding(14)
            .background(glassBg)
    }

    private var categoryPicker: some View {
        Menu {
            ForEach(Category.allCases) { c in
                Button { category = c } label: {
                    if category == c { Label(c.rawValue, systemImage: "checkmark") }
                    else { Text(c.rawValue) }
                }
            }
        } label: {
            HStack {
                Text(category.rawValue)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(glassBg)
        }
    }

    private var roomPicker: some View {
        Menu {
            ForEach(rooms, id: \.self) { r in
                Button { location = r } label: {
                    if location == r { Label(r, systemImage: "checkmark") }
                    else { Text(r) }
                }
            }
        } label: {
            HStack {
                Text(location.isEmpty ? "选择位置" : location)
                    .font(.system(size: 15))
                    .foregroundColor(location.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(glassBg)
        }
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

    private func incrementStock() { totalStock += 1 }
    private func decrementStock() { if totalStock > 0 { totalStock -= 1 } }
    private func incrementInUse() { inUse += 1 }
    private func decrementInUse() { if inUse > 0 { inUse -= 1 } }
    private func incrementAvg() { avgConsumeDays += 1 }
    private func decrementAvg() { if avgConsumeDays > 1 { avgConsumeDays -= 1 } }
    private func incrementRemind() { reminderDays += 1 }
    private func decrementRemind() { if reminderDays > 1 { reminderDays -= 1 } }
}
