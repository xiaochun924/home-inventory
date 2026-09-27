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

// MARK: - 备份 / 恢复

enum BackupManager {
    /// 导出：将全部物品（含拆封/补货记录）编码为 JSON
    static func encode(items: [InventoryItem]) throws -> Data {
        let dtos = items.map { item in
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(dtos)
    }

    /// 导入：从 JSON 解码出全新物品实例（含记录）
    static func decode(_ data: Data) throws -> [InventoryItem] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dtos = try decoder.decode([InventoryItemDTO].self, from: data)
        return dtos.map { dto in
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
