import SwiftUI
import SwiftData

/// 设置页：全局提醒规则、数据管理
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [InventoryItem]
    @AppStorage("globalReminderDays") private var globalReminderDays = 3
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("提醒设置")
                                .font(.system(size: 16, weight: .semibold))
                            HStack {
                                Text("全局提醒阈值（剩余天数）")
                                    .font(.system(size: 14))
                                Spacer()
                                Stepper("≤\(globalReminderDays) 天", value: $globalReminderDays, in: 1...30)
                                    .font(.system(size: 13))
                            }
                            Text("每个物品也可在详情页单独设置提醒规则。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }

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

    private func clearAll() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
