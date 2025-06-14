import Combine
import CoreData
// Import Foundation instead of UIKit
import Foundation
// Import the shared font extension
import SwiftUI
import WidgetKit

struct JournalView: View {
    @StateObject private var journalModel = JournalModel()
    @FocusState private var focusedField: Field?
    @EnvironmentObject var appState: AppState
    @State private var showAutoSaveBanner: Bool = false

    // --- App Group UserDefaults ---
    private var intentionKey = "widget_intention"
    private var goalKey = "widget_goal"
    private let appGroupId = "group.tabbyjournal"
    // Helper to check if editing today
    private var isEditingToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(Date())
    }

    enum Field: Hashable {
        case intention, goal, reflection
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(
                            Date.now.formatted(
                                .dateTime
                                    .month(.wide)
                                    .day()
                                    .year()
                            )
                        )
                        .font(.garamondBold(size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(Color("CardText"))
                        .padding(.top, 32)
                        .padding(.leading, 16)
                        .padding(.bottom, 8)
                        // Intention Section
                        SectionCard(
                            icon: "house.fill",
                            title: "Intention",
                            placeholder: "What do you want to focus on today?",
                            text: $journalModel.intention,
                            field: .intention
                        )
                        .focused($focusedField, equals: .intention)
                        .onChange(of: journalModel.intention) { _ in
                            autosave()
                            if isEditingToday { updateWidgetIntentionGoal() }
                        }

                        // Goal Section
                        SectionCard(
                            icon: "checkmark.seal.fill",
                            title: "Goal",
                            placeholder: "What are 2-3 tasks you want to work on today?",
                            text: $journalModel.goal,
                            field: .goal
                        )
                        .focused($focusedField, equals: .goal)
                        .onChange(of: journalModel.goal) { _ in
                            autosave()
                            if isEditingToday { updateWidgetIntentionGoal() }
                        }

                        // Reflection Section
                        SectionCard(
                            icon: "book.closed.fill",
                            title: "Reflection",
                            placeholder:
                                "What did you learn about yourself today? What adjustments will you make for the next day?",
                            text: $journalModel.reflection,
                            field: .reflection
                        )
                        .focused($focusedField, equals: .reflection)
                        .onChange(of: journalModel.reflection) { _ in
                            autosave()
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color("PageBackground").ignoresSafeArea())
                .onTapGesture {
                    focusedField = nil
                }

            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .navigationTitle("")
        }
        .onAppear {
            // Make sure the model has access to our AppState
            print("JournalView appeared, assigning AppState to JournalModel")
            JournalModel.sharedAppState = appState
        }
    }

    private func autosave() {
        journalModel.saveAllFields()
        appState.journalUpdated()
        // Write to App Group UserDefaults for widget
        // UserDefaults.standard.set(journalModel.intention, forKey: intentionKey)
        // UserDefaults.standard.set(journalModel.goal, forKey: goalKey)
        // WidgetCenter.shared.reloadAllTimelines()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        }
    }

    // --- Real-time widget update helper ---
    private func updateWidgetIntentionGoal() {
        if let userDefaults = UserDefaults(suiteName: appGroupId) {
            userDefaults.set(journalModel.intention, forKey: intentionKey)
            userDefaults.set(journalModel.goal, forKey: goalKey)
            WidgetCenter.shared.reloadAllTimelines()
            print("[Widget] Updated intention: \(journalModel.intention), goal: \(journalModel.goal)")
        }
    }
}

// Helper to dismiss the keyboard
#if canImport(UIKit)
    extension View {
        func hideKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
#endif

struct SectionCard: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: JournalView.Field
    
    // Minimum height for the text editor
    private let minHeight: CGFloat = 95
    
    // Calculate height based on text content
    private func calculateHeight(for text: String) -> CGFloat {
        let baseHeight = minHeight
        let approximateLineHeight: CGFloat = 20 // Approximate line height for the font
        let approximateCharsPerLine: CGFloat = 40 // Approximate characters per line
        
        // Calculate number of lines needed (rough estimate)
        let numberOfLines = max(1, ceil(CGFloat(text.count) / approximateCharsPerLine))
        let estimatedHeight = max(baseHeight, numberOfLines * approximateLineHeight)
        
        return estimatedHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.garamondBold(size: 22))
                    .foregroundColor(Color("CardText"))
                Text(title)
                    .font(.garamondBold(size: 20))
                    .foregroundColor(Color("CardText"))
            }
            ZStack(alignment: .topLeading) {
                // White background for text area with dynamic height
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: calculateHeight(for: text))
                
                TextEditor(text: $text)
                    .frame(minHeight: calculateHeight(for: text))
                    .padding(4)
                    .font(.garamond(size: 16))
                    .background(Color.white)
                    .foregroundColor(Color("CardText"))
                    .cornerRadius(12)
                    .colorScheme(.light)  // Force light mode

                if text.isEmpty {
                    Text(placeholder)
                        .font(.garamondItalic(size: 16))
                        .foregroundColor(Color("PlaceholderText"))
                        .padding(EdgeInsets(top: 16, leading: 12, bottom: 0, trailing: 0))
                        .allowsHitTesting(false)
                        .zIndex(1)  // Ensure placeholder is above TextEditor
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("CardBackground").opacity(0.7), lineWidth: 1)
            )
        }
        .padding(12)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    JournalView()
}
