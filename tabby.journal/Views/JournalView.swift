import SwiftUI
import Combine
import CoreData

// Import Foundation instead of UIKit
import Foundation

struct JournalView: View {
    // Create the model directly here 
    @StateObject private var journalModel = JournalModelStub()
    @FocusState private var focusedField: Field?
    
    // Simple stub for when the real model isn't available
    class JournalModelStub: ObservableObject {
        @Published var intention: String = ""
        @Published var goal: String = ""
        @Published var reflection: String = ""
    }
    
    enum Field: Hashable {
        case intention, goal, reflection
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 12)
                    // Intention Section
                    SectionCard(
                        icon: "house.fill",
                        title: "Intention",
                        placeholder: "What do you want to focus on today?",
                        text: $journalModel.intention,
                        field: .intention
                    )
                    .focused($focusedField, equals: .intention)
                    
                    // Goal Section
                    SectionCard(
                        icon: "checkmark.seal.fill",
                        title: "Goal",
                        placeholder: "What are 2-3 tasks you want to work on today?",
                        text: $journalModel.goal,
                        field: .goal
                    )
                    .focused($focusedField, equals: .goal)
                    
                    // Reflection Section
                    SectionCard(
                        icon: "book.closed.fill",
                        title: "Reflection",
                        placeholder: "What did you learn about yourself today? What adjustments will you make for the next day?",
                        text: $journalModel.reflection,
                        field: .reflection
                    )
                    .focused($focusedField, equals: .reflection)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color("PageBackground").ignoresSafeArea())
            .onTapGesture {
                focusedField = nil
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .navigationTitle(
                Date.now.formatted(
                    .dateTime
                        .month(.wide)
                        .day()
                        .year()
                )
            )
        }
    }
}

// Helper to dismiss the keyboard
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct SectionCard: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: JournalView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(Color("CardText"))
                Text(title)
                    .font(.title3).bold()
                    .foregroundColor(Color("CardText"))
            }
            ZStack(alignment: .topLeading) {
                // White background for text area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 90)
                
                TextEditor(text: $text)
                    .frame(height: 90)
                    .padding(4)
                    .background(Color.white)
                    .foregroundColor(Color("CardText"))
                    .cornerRadius(12)
                    .colorScheme(.light) // Force light mode
                
                if text.isEmpty {
                    Text(placeholder)
                        .italic()
                        .foregroundColor(Color("PlaceholderText"))
                        .padding(EdgeInsets(top: 16, leading: 12, bottom: 0, trailing: 0))
                        .allowsHitTesting(false)
                        .zIndex(1) // Ensure placeholder is above TextEditor
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("CardBackground").opacity(0.7), lineWidth: 1)
            )
        }
        .padding(14)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    JournalView()
} 
