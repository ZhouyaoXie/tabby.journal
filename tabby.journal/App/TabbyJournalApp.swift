import SwiftUI
import CoreData
import UIKit

@main
struct TabbyJournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistentContainer: NSPersistentContainer = CoreDataManager.shared.persistentContainer
    
    init() {
        // Configure navigation bar appearance
        let cardTextColor = UIColor(Color("CardText"))
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: cardTextColor
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: cardTextColor
        ]

        // Ensure the viewContext merges changes predictably
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
    }
} 