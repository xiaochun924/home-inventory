import SwiftUI
import SwiftData

/// App 入口：家庭库存管理（Home Inventory）
@main
struct HomeInventoryApp: App {
    /// 全局共享的 SwiftData 容器，负责所有库存数据的持久化存储
    let container: ModelContainer

    @MainActor
    init() {
        let schema = Schema([
            InventoryItem.self,
            UnpackRecord.self,
            RestockRecord.self
        ])
        // 将历史版本标记为迁移未来使用，此处直接使用最新配置
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 初始化失败时退化为内存容器，避免崩溃
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
