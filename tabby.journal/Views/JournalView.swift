import Combine
import CoreData
// Import Foundation instead of UIKit
import Foundation
// Import the shared font extension
import SwiftUI

struct JournalView: View {
    @StateObject private var journalModel = JournalModel()
    @FocusState private var focusedField: Field?
    @EnvironmentObject var appState: AppState
    @State private var showCompleteBanner: Bool = false

    enum Field: Hashable {
        case intention, goal, reflection
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(
                            Date.now.formatted(
                                .dateTime
                                    .month(.wide)
                                    .day()
                                    .year()
                            )
                        )
                        .font(.garamondBold(size: 34))
                        .fontWeight(.bold)
                        .foregroundColor(Color("CardText"))
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
                            placeholder:
                                "What did you learn about yourself today? What adjustments will you make for the next day?",
                            text: $journalModel.reflection,
                            field: .reflection
                        )
                        .focused($focusedField, equals: .reflection)

                        // Complete Button
                        Button(action: {
                            // Save all fields
                            journalModel.saveAllFields()
                            // Update AppState
                            appState.journalUpdated()
                            // Show confirmation banner
                            withAnimation {
                                showCompleteBanner = true
                            }
                            // Hide keyboard
                            focusedField = nil
                            // Hide banner after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCompleteBanner = false
                                }
                            }
                        }) {
                            Text("Complete Journal")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.4, green: 0.3, blue: 0.6))
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color("PageBackground").ignoresSafeArea())
                .onTapGesture {
                    focusedField = nil
                }

                // Completion confirmation banner
                if showCompleteBanner {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Journal saved!")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
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
            .navigationTitle("🐈")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // .navigationTitle(
            //     Date.now.formatted(
            //         .dateTime
            //             .month(.wide)
            //             .day()
            //             .year()
            //     )
            // )
            // .navigationBarTitleDisplayMode(.inline)
            // .toolbar {
            //     ToolbarItem(placement: .principal) {
            //         Text(
            //             Date.now.formatted(
            //                 .dateTime
            //                     .month(.wide)
            //                     .day()
            //                     .year()
            //             )
            //         )
            //         .font(.garamondBold(size: 18))
            //         .foregroundColor(Color("CardText"))
            //     }
            // }
        }
        .onAppear {
            // Make sure the model has access to our AppState
            print("JournalView appeared, assigning AppState to JournalModel")
            JournalModel.sharedAppState = appState
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.garamondBold(size: 22))
                    .foregroundColor(Color("CardText"))
                Text(title)
                    .font(.garamondBold(size: 20))
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
        .padding(14)
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    JournalView()
}
