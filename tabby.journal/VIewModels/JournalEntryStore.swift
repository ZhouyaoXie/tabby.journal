import Foundation

class JournalEntryStore: ObservableObject {
    @Published var intention: String = ""
    @Published var goal: String = ""
    @Published var reflection: String = ""
    // Add any other fields or methods needed for syncing
}
