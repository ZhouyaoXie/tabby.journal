import SwiftUI
import CoreData
import UIKit

@main
struct TabbyJournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JournalEntry")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        return container
    }()
    
    init() {
        // Configure navigation bar appearance
        let cardTextColor = UIColor(Color("CardText"))
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: cardTextColor
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: cardTextColor
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
    }
} 