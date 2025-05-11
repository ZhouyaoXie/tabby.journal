import XCTest
import CoreData
@testable import tabby_journal

class EnhancedCoreDataManagerTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    var mockContainer: NSPersistentContainer!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create a fresh in-memory persistent store for each test
        mockContainer = createInMemoryContainer()
        
        // Create test-specific subclass that uses our in-memory store
        class TestCoreDataManager: CoreDataManager {
            let testContainer: NSPersistentContainer

            init(container: NSPersistentContainer) {
                self.testContainer = container
                super.init()
            }

            override var persistentContainer: NSPersistentContainer {
                get { testContainer }
                set { /* no-op for test subclass */ }
            }
        }
        
        coreDataManager = TestCoreDataManager(container: mockContainer)
    }
    
    override func tearDown() {
        // Clean up references - no need to delete objects as we're using a fresh store each time
        mockContainer = nil
        coreDataManager = nil
        super.tearDown()
    }
    
    // Helper method to create a fresh in-memory container
    private func createInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "JournalEntry")
        
        // Configure for in-memory storage
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        // Important: Use a unique URL for each test to ensure isolation
        description.url = URL(fileURLWithPath: "/dev/null/test-\(UUID().uuidString)")
        
        container.persistentStoreDescriptions = [description]
        
        // Synchronously load the persistent store
        container.loadPersistentStores { description, error in
            if let error = error {
                XCTFail("Failed to create in-memory coordinator: \(error)")
            }
        }
        
        return container
    }
    
    // MARK: - Creation Tests
    
    func testCreateJournalEntryWithAllFields() {
        // Test: Create entry with all fields populated
        let date = Date()
        let entry = coreDataManager.createJournalEntry(
            date: date,
            intention: "Test intention",
            goal: "Test goal",
            reflection: "Test reflection",
            mood: "happy"
        ) as? NSManagedObject
        
        // Verify all fields are correctly set
        XCTAssertNotNil(entry, "Entry should be created successfully")
        XCTAssertEqual(entry?.value(forKey: "intention") as? String, "Test intention")
        XCTAssertEqual(entry?.value(forKey: "goal") as? String, "Test goal")
        XCTAssertEqual(entry?.value(forKey: "reflection") as? String, "Test reflection")
        XCTAssertEqual(entry?.value(forKey: "mood") as? String, "happy")
        
        // Verify date normalization to start of day
        let calendar = Calendar.current
        let storedDate = entry?.value(forKey: "date") as? Date
        XCTAssertNotNil(storedDate)
        XCTAssertEqual(calendar.startOfDay(for: date), storedDate)
    }
    
    func testCreateJournalEntryWithEmptyFields() {
        // Test: Create entry with empty strings (not nil)
        let date = Date()
        let entry = coreDataManager.createJournalEntry(
            date: date,
            intention: "",
            goal: "",
            reflection: "",
            mood: ""
        ) as? NSManagedObject
        
        // Verify empty strings are saved as empty strings, not nil
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.value(forKey: "intention") as? String, "")
        XCTAssertEqual(entry?.value(forKey: "goal") as? String, "")
        XCTAssertEqual(entry?.value(forKey: "reflection") as? String, "")
        XCTAssertEqual(entry?.value(forKey: "mood") as? String, "")
    }
    
    func testCreateJournalEntryWithExtremeDate() {
        // Test: Create entry with extreme date values (far past/future)
        // Tests the date handling capabilities
        
        // Far past: January 1, 1900
        var dateComponents = DateComponents()
        dateComponents.year = 1900
        dateComponents.month = 1
        dateComponents.day = 1
        let farPastDate = Calendar.current.date(from: dateComponents)!
        
        // Far future: January 1, 2100
        dateComponents.year = 2100
        let farFutureDate = Calendar.current.date(from: dateComponents)!
        
        // Create entries with extreme dates
        let pastEntry = coreDataManager.createJournalEntry(date: farPastDate, intention: "Past intention") as? NSManagedObject
        let futureEntry = coreDataManager.createJournalEntry(date: farFutureDate, intention: "Future intention") as? NSManagedObject
        
        // Verify dates are handled correctly
        XCTAssertNotNil(pastEntry)
        XCTAssertNotNil(futureEntry)
        
        let storedPastDate = pastEntry?.value(forKey: "date") as? Date
        let storedFutureDate = futureEntry?.value(forKey: "date") as? Date
        
        XCTAssertEqual(Calendar.current.startOfDay(for: farPastDate), storedPastDate)
        XCTAssertEqual(Calendar.current.startOfDay(for: farFutureDate), storedFutureDate)
    }
    
    // MARK: - Fetch Tests
    
    func testFetchJournalEntryWithTimezoneChange() {
        // Test: Verify that date fetching works across timezone changes
        
        // Create a date with a specific timezone
        let originalTimeZone = TimeZone.current
        
        // Create entry in current timezone
        let date = Date()
        let createdEntry = coreDataManager.createJournalEntry(date: date, intention: "Timezone test")
        
        // Simulate timezone change by changing system timezone
        // Note: In real implementation we would mock the TimeZone rather than actually changing it
        if let newTimeZone = TimeZone(identifier: "America/Los_Angeles") {
            // Fetch entry in different timezone
            TimeZone.ReferenceType.default = newTimeZone
            let fetchedEntry = coreDataManager.fetchJournalEntry(for: date)
            
            // Verify entry can still be found despite timezone change
            XCTAssertNotNil(fetchedEntry)
            XCTAssertEqual(fetchedEntry?.value(forKey: "intention") as? String, "Timezone test")
            
            // Reset timezone
            TimeZone.ReferenceType.default = originalTimeZone
        }
    }
    
    func testFetchNonExistentEntry() {
        // Test: Fetching an entry that doesn't exist should return nil
        
        // Create entry for today
        let today = Date()
        coreDataManager.createJournalEntry(date: today, intention: "Today's entry")
        
        // Try to fetch entry for tomorrow (which doesn't exist)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let fetchedEntry = coreDataManager.fetchJournalEntry(for: tomorrow)
        
        // Verify nil is returned
        XCTAssertNil(fetchedEntry, "Should return nil for date with no entry")
    }
    
    func testFetchEntryExactTimeOfDay() {
        // Test: Verify fetching works regardless of time of day
        let calendar = Calendar.current
        let today = Date()
        
        // Create entry at midnight
        let entry = coreDataManager.createJournalEntry(date: today, intention: "Test entry")
        
        // Try fetching at various times throughout the day
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!
        let almostMidnight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today)!
        
        // Verify same entry is fetched regardless of time
        XCTAssertNotNil(coreDataManager.fetchJournalEntry(for: morning))
        XCTAssertNotNil(coreDataManager.fetchJournalEntry(for: noon))
        XCTAssertNotNil(coreDataManager.fetchJournalEntry(for: evening))
        XCTAssertNotNil(coreDataManager.fetchJournalEntry(for: almostMidnight))
        
        // Verify all fetched entries are the same one
        XCTAssertEqual(
            coreDataManager.fetchJournalEntry(for: morning)?.value(forKey: "id") as? UUID,
            entry.value(forKey: "id") as? UUID
        )
    }
    
    // MARK: - Today's Entry Tests
    
    func testGetOrCreateTodaysEntryMultipleCalls() {
        // Test: Multiple calls to getOrCreateTodaysEntry should return the same entry
        
        // First call should create new entry
        let firstEntry = coreDataManager.getOrCreateTodaysEntry()
        let firstId = firstEntry.value(forKey: "id") as? UUID
        XCTAssertNotNil(firstId)
        
        // Second call should return existing entry
        let secondEntry = coreDataManager.getOrCreateTodaysEntry()
        let secondId = secondEntry.value(forKey: "id") as? UUID
        
        // Verify IDs match
        XCTAssertEqual(firstId, secondId, "Multiple calls should return the same entry")
    }
    
    func testTodaysEntryAfterMidnight() {
        // Test: Verify today's entry changes after midnight
        // Note: This simulates passage of time rather than actually waiting
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create today's entry
        let todayEntry = coreDataManager.getOrCreateTodaysEntry()
        let todayId = todayEntry.value(forKey: "id") as? UUID
        
        // Simulate date change to tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        
        // Using the checkAndUpdateForDateChange logic from JournalModel
        // Create a new entry for tomorrow and verify it's different
        let tomorrowEntry = coreDataManager.getOrCreateTodaysEntry()
        
        // We'd need to mock Date.now to fully test this
        // This is just demonstrating the concept
        XCTAssertNotNil(tomorrowEntry)
    }
    
    // MARK: - Update Tests
    
    func testUpdateWithInvalidValues() {
        // Test: Update with very large text values
        
        // Create entry
        let entry = coreDataManager.createJournalEntry(date: Date()) as? NSManagedObject
        XCTAssertNotNil(entry)
        
        // Create a very large string (100KB)
        let largeString = String(repeating: "A", count: 100 * 1024)
        
        // Update with large value
        coreDataManager.updateJournalEntryFields(
            entry!,
            intention: largeString,
            goal: nil,
            reflection: nil
        )
        
        // Verify update succeeded (Core Data should handle this)
        XCTAssertEqual(entry?.value(forKey: "intention") as? String, largeString)
    }
    
    func testUpdateNonexistentEntry() {
        // Test: Try to update a deleted entry
        
        // Create and immediately delete an entry
        let entry = coreDataManager.createJournalEntry(date: Date()) as? NSManagedObject
        XCTAssertNotNil(entry)
        coreDataManager.deleteJournalEntry(entry!)
        
        // Try to update the deleted entry
        // This should not crash, even though the entry is deleted
        coreDataManager.updateJournalEntryFields(
            entry!,
            intention: "Updated intention",
            goal: nil,
            reflection: nil
        )
        
        // No assertion needed - we're testing that it doesn't crash
    }
    
    func testUpdateFieldsSequentially() {
        // Test: Update each field one at a time
        
        // Create entry
        let entry = coreDataManager.createJournalEntry(date: Date()) as? NSManagedObject
        XCTAssertNotNil(entry)
        
        // Update intention
        coreDataManager.updateJournalEntryFields(
            entry!,
            intention: "Updated intention",
            goal: nil,
            reflection: nil
        )
        
        // Update goal
        coreDataManager.updateJournalEntryFields(
            entry!,
            intention: nil,
            goal: "Updated goal",
            reflection: nil
        )
        
        // Update reflection
        coreDataManager.updateJournalEntryFields(
            entry!,
            intention: nil,
            goal: nil,
            reflection: "Updated reflection"
        )
        
        // Verify all fields were updated
        XCTAssertEqual(entry?.value(forKey: "intention") as? String, "Updated intention")
        XCTAssertEqual(entry?.value(forKey: "goal") as? String, "Updated goal")
        XCTAssertEqual(entry?.value(forKey: "reflection") as? String, "Updated reflection")
    }
    
    // MARK: - Date Range Tests
    
    func testFetchEmptyDateRange() {
        // Test: Fetch with invalid date range (end before start)
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Try to fetch with end date before start date
        let entries = coreDataManager.fetchJournalEntries(from: today, to: yesterday)
        
        // Should return empty array
        XCTAssertEqual(entries.count, 0, "Invalid date range should return empty array")
    }
    
    func testFetchLargeDataRange() {
        // Test: Fetch entries over a very large date range
        
        // Create entries
        let today = Date()
        coreDataManager.createJournalEntry(date: today, intention: "Today's entry")
        
        // Create a date 10 years ago
        let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: today)!
        
        // Create a date 10 years in future
        let tenYearsLater = Calendar.current.date(byAdding: .year, value: 10, to: today)!
        
        // Fetch over 20 year span
        let entries = coreDataManager.fetchJournalEntries(from: tenYearsAgo, to: tenYearsLater)
        
        // Should find the one entry
        XCTAssertEqual(entries.count, 1, "Should find one entry in large date range")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteAndRecreate() {
        // Test: Delete an entry and then create a new one for same date
        
        let today = Date()
        
        // Create and delete an entry
        let entry = coreDataManager.createJournalEntry(date: today, intention: "Original entry") as? NSManagedObject
        XCTAssertNotNil(entry)
        coreDataManager.deleteJournalEntry(entry!)
        
        // Verify it's gone
        XCTAssertNil(coreDataManager.fetchJournalEntry(for: today))
        
        // Create new entry for same date
        let newEntry = coreDataManager.createJournalEntry(date: today, intention: "New entry") as? NSManagedObject
        XCTAssertNotNil(newEntry)
        
        // Verify it's different from original
        XCTAssertNotEqual(
            entry?.value(forKey: "id") as? UUID,
            newEntry?.value(forKey: "id") as? UUID
        )
        
        // Verify content is correct
        XCTAssertEqual(newEntry?.value(forKey: "intention") as? String, "New entry")
    }
    
    func testDeleteAlreadyDeletedEntry() {
        // Test: Trying to delete an already deleted entry
        
        // Create and delete an entry
        let entry = coreDataManager.createJournalEntry(date: Date()) as? NSManagedObject
        XCTAssertNotNil(entry)
        coreDataManager.deleteJournalEntry(entry!)
        
        // Try to delete it again
        // This shouldn't crash
        coreDataManager.deleteJournalEntry(entry!)
        
        // No assertion needed - we're testing it doesn't crash
    }
    
    
    func testUnicodeAndSpecialCharacters() {
        // Test: Ensure special characters are handled correctly
        
        // Create string with emojis, unicode, and special characters
        let specialString = "🙂 Unicode test: é è ê ñ 中文 عربى 한국어 \u{0000}" // null byte included
        
        // Create entry with special characters
        let entry = coreDataManager.createJournalEntry(
            date: Date(),
            intention: specialString,
            goal: specialString,
            reflection: specialString
        ) as? NSManagedObject
        
        // Verify special characters were stored correctly
        XCTAssertEqual(entry?.value(forKey: "intention") as? String, specialString)
        XCTAssertEqual(entry?.value(forKey: "goal") as? String, specialString)
        XCTAssertEqual(entry?.value(forKey: "reflection") as? String, specialString)
    }
} 
