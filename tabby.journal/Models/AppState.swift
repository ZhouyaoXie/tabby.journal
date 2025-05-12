import Foundation
import Combine

class AppState: ObservableObject {
    // Use UUID instead of Date for more reliable change detection
    @Published var journalUpdateId: UUID = UUID()
    @Published var lastJournalUpdate: Date = Date()
    
    func journalUpdated() {
        // Generate a new UUID to ensure subscribers detect the change
        self.journalUpdateId = UUID()
        self.lastJournalUpdate = Date()
        print("===== JOURNAL UPDATE SIGNAL =====")
        print("Journal update signaled with ID: \(self.journalUpdateId)")
        print("Timestamp: \(self.lastJournalUpdate)")
        print("==================================")
    }
} 