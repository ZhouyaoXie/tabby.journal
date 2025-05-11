import Foundation
import CoreData
import SwiftUI

public class CoreDataManager {
    public static let shared = CoreDataManager()
    
    public init() {}
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JournalEntry")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    public var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - CRUD Operations
    
    public func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    public func createJournalEntry(date: Date, intention: String? = nil, goal: String? = nil, reflection: String? = nil, mood: String? = nil) -> NSManagedObject {
        let entry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: context)
        entry.setValue(UUID(), forKey: "id")
        entry.setValue(Calendar.current.startOfDay(for: date), forKey: "date")
        entry.setValue(Date(), forKey: "createdAt")
        entry.setValue(Date(), forKey: "updatedAt")
        entry.setValue(intention, forKey: "intention")
        entry.setValue(goal, forKey: "goal")
        entry.setValue(reflection, forKey: "reflection")
        entry.setValue(mood, forKey: "mood")
        
        saveContext()
        return entry
    }
    
    public func fetchJournalEntry(for date: Date) -> NSManagedObject? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching journal entry: \(error)")
            return nil
        }
    }
    
    public func getOrCreateTodaysEntry() -> NSManagedObject {
        let today = Date()
        
        if let existingEntry = fetchJournalEntry(for: today) {
            return existingEntry
        }
        
        return createJournalEntry(date: today)
    }
    
    public func updateJournalEntryFields(_ entry: NSManagedObject, intention: String?, goal: String?, reflection: String?) {
        var needsSave = false
        
        if let intention = intention, entry.value(forKey: "intention") as? String != intention {
            entry.setValue(intention, forKey: "intention")
            needsSave = true
        }
        
        if let goal = goal, entry.value(forKey: "goal") as? String != goal {
            entry.setValue(goal, forKey: "goal")
            needsSave = true
        }
        
        if let reflection = reflection, entry.value(forKey: "reflection") as? String != reflection {
            entry.setValue(reflection, forKey: "reflection")
            needsSave = true
        }
        
        if needsSave {
            entry.setValue(Date(), forKey: "updatedAt")
            saveContext()
        }
    }
    
    public func fetchJournalEntries(from startDate: Date, to endDate: Date) -> [NSManagedObject] {
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfStartDate as NSDate, endOfEndDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching journal entries: \(error)")
            return []
        }
    }
    
    public func updateJournalEntry(_ entry: NSManagedObject, intention: String? = nil, goal: String? = nil, reflection: String? = nil, mood: String? = nil) {
        if let intention = intention {
            entry.setValue(intention, forKey: "intention")
        }
        if let goal = goal {
            entry.setValue(goal, forKey: "goal")
        }
        if let reflection = reflection {
            entry.setValue(reflection, forKey: "reflection")
        }
        if let mood = mood {
            entry.setValue(mood, forKey: "mood")
        }
        
        entry.setValue(Date(), forKey: "updatedAt")
        saveContext()
    }
    
    public func deleteJournalEntry(_ entry: NSManagedObject) {
        context.delete(entry)
        saveContext()
    }
    
    public func deleteAllJournalEntries() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "JournalEntry")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            saveContext()
        } catch {
            print("Error deleting all journal entries: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    public func getEntryValues(_ entry: NSManagedObject) -> (intention: String?, goal: String?, reflection: String?) {
        let intention = entry.value(forKey: "intention") as? String
        let goal = entry.value(forKey: "goal") as? String
        let reflection = entry.value(forKey: "reflection") as? String
        
        return (intention, goal, reflection)
    }
} 
