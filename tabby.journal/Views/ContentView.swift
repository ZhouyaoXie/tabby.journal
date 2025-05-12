import SwiftUI
import CoreData
import Foundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var appState = AppState()
    
    // Create a stub model for non-dependent views
    class JournalModelStub: ObservableObject {
        @Published var intention: String = ""
        @Published var goal: String = ""
        @Published var reflection: String = ""
    }
    
    @StateObject private var journalModel = JournalModelStub()
    
    var body: some View {
        TabView {
            JournalView()
                .environmentObject(appState)
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
            
            CalendarView()
                .environmentObject(appState)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
        }
    }
}

#Preview {
    let container = NSPersistentContainer(name: "JournalEntry")
    container.loadPersistentStores { _, _ in }
    
    let context = container.viewContext
    let contentView = ContentView()
        .environment(\.managedObjectContext, context)
    return contentView
} 
