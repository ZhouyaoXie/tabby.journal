import Foundation
import CoreData

struct JournalEntryExport: Codable {
    let date: Date
    let intention: String?
    let goal: String?
    let reflection: String?
}

class JournalBackupManager {
    static let shared = JournalBackupManager()
    private init() {}
    
    // MARK: - Backup
    func backupAllEntries(context: NSManagedObjectContext) throws -> URL {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        let entries = try context.fetch(fetchRequest)
        let exportEntries: [JournalEntryExport] = entries.compactMap { entry in
            guard let date = entry.value(forKey: "date") as? Date else { return nil }
            let intention = entry.value(forKey: "intention") as? String
            let goal = entry.value(forKey: "goal") as? String
            let reflection = entry.value(forKey: "reflection") as? String
            return JournalEntryExport(date: date, intention: intention, goal: goal, reflection: reflection)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportEntries)
        let url = Self.backupFileURL()
        try data.write(to: url)
        return url
    }
    
    // MARK: - Restore
    func restoreEntriesFromBackup(context: NSManagedObjectContext) throws {
        let url = Self.backupFileURL()
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importedEntries = try decoder.decode([JournalEntryExport].self, from: data)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        let existingEntries = try context.fetch(fetchRequest)
        for imported in importedEntries {
            // Check if entry for this date exists
            if let existing = existingEntries.first(where: { ($0.value(forKey: "date") as? Date)?.startOfDay == imported.date.startOfDay }) {
                existing.setValue(imported.intention, forKey: "intention")
                existing.setValue(imported.goal, forKey: "goal")
                existing.setValue(imported.reflection, forKey: "reflection")
            } else {
                let newEntry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: context)
                newEntry.setValue(imported.date, forKey: "date")
                newEntry.setValue(imported.intention, forKey: "intention")
                newEntry.setValue(imported.goal, forKey: "goal")
                newEntry.setValue(imported.reflection, forKey: "reflection")
            }
        }
        try context.save()
    }
    
    // MARK: - File URL
    static func backupFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("journal_backup.json")
    }
}

// Helper to compare dates by day
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
} 