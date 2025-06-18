import SwiftUI
import CoreData
import Foundation
import SwiftUI // for Font extension

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var appState = AppState()
    @StateObject private var entryStore = JournalEntryStore()
    @State private var selectedTab: Int = 0
    
    // Create a stub model for non-dependent views
    class JournalModelStub: ObservableObject {
        @Published var intention: String = ""
        @Published var goal: String = ""
        @Published var reflection: String = ""
    }
    
    @StateObject private var journalModel = JournalModelStub()
    
    init() {
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
    
    var body: some View {
        ZStack {
            Color("PageBackground").ignoresSafeArea()
            TabView(selection: $selectedTab) {
                JournalView(entryStore: entryStore)
                    .environmentObject(appState)
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(0)
                
                CalendarView(entryStore: entryStore)
                    .environmentObject(appState)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
                    .tag(2)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenJournalTab"))) { _ in
                selectedTab = 0
            }
        }
    }
}

#Preview {
    let container: NSPersistentContainer = NSPersistentContainer(name: "JournalEntry")
    container.loadPersistentStores { _, _ in }
    
    let context = container.viewContext
    let contentView = ContentView()
        .environment(\.managedObjectContext, context)
    return contentView
} 
