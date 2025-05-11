import SwiftUI
import CoreData
import UIKit

@main
struct TabbyJournal: App {
    let persistentContainer = NSPersistentContainer(name: "JournalEntry")
    
    init() {
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
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
            let contentView = ContentView()
            contentView
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
    }
} 