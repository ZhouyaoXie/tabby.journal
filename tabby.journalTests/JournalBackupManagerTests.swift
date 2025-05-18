import XCTest
import CoreData
@testable import tabby_journal

class JournalBackupManagerTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
    override func setUp() {
        super.setUp()
        persistentContainer = NSPersistentContainer(name: "JournalEntry")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
    }
    
    override func tearDown() {
        persistentContainer = nil
        super.tearDown()
    }
    
    func testBackupAllEntries_createsValidJSONFile() throws {
        // Insert sample entries
        let entry1 = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: context)
        entry1.setValue(UUID(), forKey: "id")
        entry1.setValue(Date(timeIntervalSince1970: 1000), forKey: "date")
        entry1.setValue(Date(timeIntervalSince1970: 1000), forKey: "createdAt")
        entry1.setValue(Date(timeIntervalSince1970: 1000), forKey: "updatedAt")
        entry1.setValue("Test Intention 1", forKey: "intention")
        entry1.setValue("Test Goal 1", forKey: "goal")
        entry1.setValue("Test Reflection 1", forKey: "reflection")
        entry1.setValue("Test Mood 1", forKey: "mood")

        let entry2 = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: context)
        entry2.setValue(UUID(), forKey: "id")
        entry2.setValue(Date(timeIntervalSince1970: 2000), forKey: "date")
        entry2.setValue(Date(timeIntervalSince1970: 2000), forKey: "createdAt")
        entry2.setValue(Date(timeIntervalSince1970: 2000), forKey: "updatedAt")
        entry2.setValue("Test Intention 2", forKey: "intention")
        entry2.setValue("Test Goal 2", forKey: "goal")
        entry2.setValue("Test Reflection 2", forKey: "reflection")
        entry2.setValue("Test Mood 2", forKey: "mood")

        try context.save()
        
        // Backup
        let url = try JournalBackupManager.shared.backupAllEntries(context: context)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([JournalEntryExport].self, from: data)
        
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.contains { $0.intention == "Test Intention 1" })
        XCTAssertTrue(entries.contains { $0.goal == "Test Goal 1" })
        XCTAssertTrue(entries.contains { $0.reflection == "Test Reflection 1" })
        XCTAssertTrue(entries.contains { $0.intention == "Test Intention 2" })
        XCTAssertTrue(entries.contains { $0.goal == "Test Goal 2" })
        XCTAssertTrue(entries.contains { $0.reflection == "Test Reflection 2" })
    }
} 