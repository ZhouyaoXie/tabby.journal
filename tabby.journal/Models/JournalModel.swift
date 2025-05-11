import Foundation
import CoreData
import SwiftUI
import Combine

class JournalModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Current journal entry fields
    @Published var intention: String = ""
    @Published var goal: String = ""
    @Published var reflection: String = ""
    
    // Current journal entry
    private var currentEntry: NSManagedObject?
    
    // Store auto-save timers
    private var intentionSaveTimer: Timer?
    private var goalSaveTimer: Timer?
    private var reflectionSaveTimer: Timer?
    
    init() {
        // Set up publishers to observe text changes and save after a delay
        setupPublishers()
        
        // Load today's entry when initialized
        loadTodaysEntry()
        
        // Set up notifications for app lifecycle
        setupNotifications()
    }
    
    private func setupPublishers() {
        // Save intention after typing stops for half a second
        $intention
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.saveField(field: "intention", value: newValue)
            }
            .store(in: &cancellables)
        
        // Save goal after typing stops for half a second
        $goal
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.saveField(field: "goal", value: newValue)
            }
            .store(in: &cancellables)
        
        // Save reflection after typing stops for half a second
        $reflection
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.saveField(field: "reflection", value: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        // Save when app moves to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveCurrentEntry),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Check for date change when app comes to foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAndUpdateForDateChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    func loadTodaysEntry() {
        // Get or create today's entry
        currentEntry = coreDataManager.getOrCreateTodaysEntry()
        
        if let entry = currentEntry {
            let values = coreDataManager.getEntryValues(entry)
            
            // Update published properties with values from CoreData
            DispatchQueue.main.async { [weak self] in
                self?.intention = values.intention ?? ""
                self?.goal = values.goal ?? ""
                self?.reflection = values.reflection ?? ""
            }
        }
    }
    
    private func saveField(field: String, value: String) {
        guard let entry = currentEntry else {
            // Create entry if it doesn't exist yet
            currentEntry = coreDataManager.getOrCreateTodaysEntry()
            saveField(field: field, value: value)
            return
        }
        
        // Update only the specific field
        switch field {
        case "intention":
            coreDataManager.updateJournalEntryFields(entry, intention: value, goal: nil, reflection: nil)
        case "goal":
            coreDataManager.updateJournalEntryFields(entry, intention: nil, goal: value, reflection: nil)
        case "reflection":
            coreDataManager.updateJournalEntryFields(entry, intention: nil, goal: nil, reflection: value)
        default:
            break
        }
    }
    
    @objc private func saveCurrentEntry() {
        guard let entry = currentEntry else { return }
        
        coreDataManager.updateJournalEntryFields(
            entry,
            intention: intention,
            goal: goal,
            reflection: reflection
        )
    }
    
    @objc private func checkAndUpdateForDateChange() {
        guard let entry = currentEntry else { return }
        
        // If the current entry is not for today, load today's entry
        let today = Date()
        if let entryDate = entry.value(forKey: "date") as? Date {
            let calendar = Calendar.current
            if !calendar.isDate(entryDate, inSameDayAs: today) {
                loadTodaysEntry()
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }
} 