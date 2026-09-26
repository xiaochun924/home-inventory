# 家庭库存管理（Home Inventory）

一款用 **Swift 6 + SwiftUI + SwiftData** 编写的 iOS 原生家庭消耗品库存管理 App。
界面参考「有余」，全局采用**液态玻璃（Glass Liquid）**设计风格：
纯透明导航栏、左上角圆形玻璃返回按钮、中间悬浮玻璃胶囊标题、完全隐藏系统导航栏、浅绿白底 + 柔光光斑。

## 功能

- **首页**：需要关注件数 / 消耗品种类统计；按「需关注」「库存充足」「尚未拆封」分区展示；
  支持按 **品类 / 房间** 筛选与关键词搜索。
- **物品详情**：品类、库存数量、存放位置、最近拆封记录与拆封进度；
  **拆封 / 补货**操作并自动生成记录；消耗预测（预计 N 天后耗尽、预计耗尽日期）；
  消耗与提醒设置（平均消耗天数、剩余≤X 天提醒规则）。
- **新增 / 编辑**：添加或修改物品的名称、品类、位置、库存、使用中、平均消耗、提醒阈值、拆封状态。
- **设置**：全局提醒阈值、数据统计、清空全部数据。
- **数据持久化**：SwiftData 本地存储，重启后数据保留；首次启动播种示例数据。

## 环境要求

- macOS + Xcode 15（或更新，需支持 Swift 6 与 iOS 17+）
- iOS 17.0+（SwiftData 要求）

## 构建方式

### 方式一：XcodeGen（推荐）

工程已提供 `project.yml`，如已安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```bash
cd HomeInventory
xcodegen generate
open HomeInventory.xcodeproj
```

### 方式二：手动创建 Xcode 工程

1. Xcode → New Project → iOS App，命名 `HomeInventory`，语言 Swift、界面 SwiftUI。
2. 用 `Sources` 目录下的所有文件覆盖同名目标文件（App 入口用 `HomeInventoryApp.swift`）。
3. 将 `Sources/Info.plist` 设为目标的 Info.plist，拖入 `Assets.xcassets`。
4. 选择目标 → Signing & Capabilities 配置你的开发者团队后即可运行。

## 工程结构

```
HomeInventory/
├── project.yml                  # XcodeGen 配置（生成 .xcodeproj）
└── Sources/
    ├── HomeInventoryApp.swift   # App 入口 + SwiftData 容器
    ├── Info.plist
    ├── Assets.xcassets/
    ├── Models/
    │   ├── InventoryItem.swift  # 库存物品模型
    │   ├── InventoryRecords.swift # 拆封 / 补货记录
    │   └── SeedData.swift       # 示例数据
    ├── Utils/Format.swift       # 日期 / 相对天数格式化
    └── Views/
        ├── RootView.swift       # 根视图 + 底部导航 + 全局背景
        ├── HomeView.swift       # 首页
        ├── ItemDetailView.swift # 详情 + 拆封/补货弹窗
        ├── ItemEditView.swift   # 新增 / 编辑
        ├── SettingsView.swift   # 设置
        └── Components/GlassComponents.swift # 液态玻璃组件（悬浮顶栏/卡片/胶囊按钮）
```

## 消耗与提醒逻辑（与参考 App 一致）

- 预计剩余可用天数 = 库存数量 × 平均消耗天数
- 拆封后开始计算预计可用天数（`拆封后开始计算预计可用天数`）
- 需关注 = 库存耗尽（≤0）或 剩余天数 ≤ 提醒阈值（默认 3 天）
- 消耗预测基于 30 天预测窗口展示

> 注意：`project.yml` 中的 `DEVELOPMENT_TEAM` 为空，运行前请先在 Xcode 的 Signing 配置自己的开发者团队。
