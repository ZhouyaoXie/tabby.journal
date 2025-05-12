import Foundation
import SwiftUI

// This file ensures AppState is properly imported everywhere
extension AppState {
    // Debug helper to verify state synchronization
    func debugRefreshState() {
        print("AppState debug check: last update was \(lastJournalUpdate)")
        print("Current journal update ID: \(journalUpdateId)")
        // Force a UI refresh by updating the timestamp
        journalUpdated()
    }
}

// Preview helper for AppState
extension AppState {
    static var preview: AppState {
        let state = AppState()
        state.journalUpdateId = UUID()
        state.lastJournalUpdate = Date()
        return state
    }
} 