import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 备份 DTO（Codable 快照，与模型字段一一对应）

struct UnpackRecordDTO: Codable {
    var id: UUID
    var date: Date
    var quantity: Int
}

struct RestockRecordDTO: Codable {
    var id: UUID
    var date: Date
    var quantity: Int
}

struct InventoryItemDTO: Codable {
    var id: UUID
    var name: String
    var brand: String
    var category: String
    var location: String
    var totalStock: Int
    var inUse: Int
    var avgConsumeDays: Int
    var reminderDays: Int
    var reminderRule: Int
    var createdAt: Date
    var isOpened: Bool
    var lastUnpackDate: Date?
    var unpackRecords: [UnpackRecordDTO]
    var restockRecords: [RestockRecordDTO]
}

/// 区域快照：名称 + 排序（底部导航顺序）
struct AreaDTO: Codable {
    var name: String
    var sortOrder: Int
}

/// 备份文件结构：区域（含顺序）+ 物品（新格式）
struct BackupFileDTO: Codable {
    var areas: [AreaDTO]
    var items: [InventoryItemDTO]
}

/// 兼容旧版备份：区域仅为名称数组
struct LegacyBackupFileDTO: Codable {
    var areas: [String]
    var items: [InventoryItemDTO]
}

/// 恢复结果
struct BackupResult {
    var areas: [AreaDTO]
    var items: [InventoryItem]
}

// MARK: - 备份 / 恢复

enum BackupManager {
    /// 导出：将全部区域（含顺序）与物品（含拆封/补货记录）编码为 JSON
    static func encode(items: [InventoryItem], areas: [InventoryArea]) throws -> Data {
        let file = BackupFileDTO(
            areas: areas.sorted { $0.sortOrder < $1.sortOrder }.map { AreaDTO(name: $0.name, sortOrder: $0.sortOrder) },
            items: items.map { dto(from: $0) }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(file)
    }

    /// 导入：优先解析新格式（区域含顺序），再兼容旧格式（区域仅名称数组），最后兼容纯物品数组
    static func decode(_ data: Data) throws -> BackupResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // 新格式：区域带 sortOrder
        if let file = try? decoder.decode(BackupFileDTO.self, from: data) {
            return BackupResult(areas: file.areas, items: file.items.map { item(from: $0) })
        }
        // 旧格式：区域仅为名称数组（按数组顺序补 sortOrder）
        if let legacy = try? decoder.decode(LegacyBackupFileDTO.self, from: data) {
            return BackupResult(
                areas: legacy.areas.enumerated().map { AreaDTO(name: $1, sortOrder: $0) },
                items: legacy.items.map { item(from: $0) }
            )
        }
        // 最旧格式：纯物品数组，无区域
        let dtos = try decoder.decode([InventoryItemDTO].self, from: data)
        return BackupResult(areas: [], items: dtos.map { item(from: $0) })
    }

    private static func dto(from item: InventoryItem) -> InventoryItemDTO {
        InventoryItemDTO(
            id: item.id,
            name: item.name,
            brand: item.brand,
            category: item.categoryRaw,
            location: item.location,
            totalStock: item.totalStock,
            inUse: item.inUse,
            avgConsumeDays: item.avgConsumeDays,
            reminderDays: item.reminderDays,
            reminderRule: item.reminderRule,
            createdAt: item.createdAt,
            isOpened: item.isOpened,
            lastUnpackDate: item.lastUnpackDate,
            unpackRecords: item.unpackRecords.map { UnpackRecordDTO(id: $0.id, date: $0.date, quantity: $0.quantity) },
            restockRecords: item.restockRecords.map { RestockRecordDTO(id: $0.id, date: $0.date, quantity: $0.quantity) }
        )
    }

    private static func item(from dto: InventoryItemDTO) -> InventoryItem {
        let item = InventoryItem(
            id: dto.id,
            name: dto.name,
            brand: dto.brand,
            category: Category(rawValue: dto.category) ?? .other,
            location: dto.location,
            totalStock: dto.totalStock,
            inUse: dto.inUse,
            avgConsumeDays: dto.avgConsumeDays,
            reminderDays: dto.reminderDays,
            reminderRule: dto.reminderRule,
            isOpened: dto.isOpened
        )
        item.createdAt = dto.createdAt
        item.lastUnpackDate = dto.lastUnpackDate
        for r in dto.unpackRecords {
            let rec = UnpackRecord(id: r.id, date: r.date, quantity: r.quantity)
            rec.item = item
            item.unpackRecords.append(rec)
        }
        for r in dto.restockRecords {
            let rec = RestockRecord(id: r.id, date: r.date, quantity: r.quantity)
            rec.item = item
            item.restockRecords.append(rec)
        }
        return item
    }
}

// MARK: - 备份文件（fileExporter 使用）

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
