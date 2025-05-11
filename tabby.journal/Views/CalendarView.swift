import SwiftUI
import CoreData
import Combine

struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var displayDates: [Date] = []
    @State private var calendarOffset: Int = 0 // Tracks the current week offset
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // Journal entry data for the selected date
    @State private var currentIntention: String = ""
    @State private var currentGoal: String = ""
    @State private var currentReflection: String = ""
    
    // Format for the header (Mon, Aug 17)
    private let dateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()
    
    // Format for the day number (17)
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PageBackground").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Date header and selector section with light purple background
                    VStack(spacing: 16) {
                        // Selected date display (Mon, Aug 17)
                        HStack {
                            Text(dateHeaderFormatter.string(from: selectedDate))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color("CardText"))
                            
                            Spacer()
                            
                            Button(action: {
                                // Reset to today
                                withAnimation {
                                    selectedDate = Date()
                                    calendarOffset = 0
                                    generateDateRange()
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(Color("CardText"))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Date navigation section
                        HStack {
                            // Previous week button
                            Button(action: {
                                withAnimation {
                                    calendarOffset -= 1
                                    generateDateRange()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(Color("CardText"))
                                    .padding(8)
                                    .background(Circle().fill(Color("CardBackground")))
                            }
                            
                            Spacer()
                            
                            // Next week button
                            Button(action: {
                                withAnimation {
                                    calendarOffset += 1
                                    generateDateRange()
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(Color("CardText"))
                                    .padding(8)
                                    .background(Circle().fill(Color("CardBackground")))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Horizontal date picker
                        ScrollViewReader { scrollView in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(displayDates, id: \.self) { date in
                                        DateCircleView(
                                            date: date,
                                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                            isToday: Calendar.current.isDateInToday(date),
                                            hasEntry: checkForJournalEntry(date),
                                            dayFormatter: dayFormatter
                                        )
                                        .id(date)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedDate = date
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                            .onAppear {
                                // Scroll to selected date when view appears
                                scrollView.scrollTo(selectedDate, anchor: .center)
                            }
                            .onChange(of: selectedDate) { newDate in
                                // Scroll to newly selected date
                                withAnimation {
                                    scrollView.scrollTo(newDate, anchor: .center)
                                }
                                
                                // Load journal entry for the selected date
                                loadJournalEntry(for: newDate)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(Color("CardBackground").opacity(0.6))
                    
                    // Journal entry display area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Intention Section
                            JournalSectionPreview(
                                title: "Intention",
                                icon: "house.fill",
                                content: currentIntention.isEmpty ? "What do you want to focus on today?" : currentIntention,
                                isEmpty: currentIntention.isEmpty
                            )
                            .onTapGesture {
                                // Navigate to JournalView and focus on intention field
                                navigateToJournalView()
                            }
                            
                            // Goal Section
                            JournalSectionPreview(
                                title: "Goal",
                                icon: "checkmark.seal.fill",
                                content: currentGoal.isEmpty ? "What are 2-3 tasks you want to work on today?" : currentGoal,
                                isEmpty: currentGoal.isEmpty
                            )
                            .onTapGesture {
                                // Navigate to JournalView and focus on goal field
                                navigateToJournalView()
                            }
                            
                            // Reflection Section
                            JournalSectionPreview(
                                title: "Reflection",
                                icon: "book.closed.fill",
                                content: currentReflection.isEmpty ? "What did you learn about yourself today? What adjustments will you make for the next day?" : currentReflection,
                                isEmpty: currentReflection.isEmpty
                            )
                            .onTapGesture {
                                // Navigate to JournalView and focus on reflection field
                                navigateToJournalView()
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }
            .navigationTitle("Journal History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                generateDateRange()
                loadJournalEntry(for: selectedDate)
            }
        }
    }
    
    // Generate dates for the horizontal date picker based on the current offset
    private func generateDateRange() {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the base date (start of the week) with the offset
        let offsetWeeks = calendar.date(byAdding: .weekOfYear, value: calendarOffset, to: today) ?? today
        let startOfWeek = calendar.date(byAdding: .day, value: -3, to: offsetWeeks) ?? offsetWeeks
        
        var dates: [Date] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                dates.append(date)
            }
        }
        
        displayDates = dates
    }
    
    // For the calendar preview, we'll simulate journal entries
    // In a real implementation, this would use CoreDataManager 
    private func loadJournalEntry(for date: Date) {
        // For now, let's simulate some data
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDateInToday(date) {
            // Today's entry
            currentIntention = "I want to focus on self-care today."
            currentGoal = "- finish calendar view UI design\n- prepare for LLM fine tuning presentation\n- spend 10 min working out"
            currentReflection = "I've been enjoying waking up early in the morning recently but I need to go to bed earlier in the evening."
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), 
                  calendar.isDate(date, inSameDayAs: yesterday) {
            // Yesterday's entry
            currentIntention = "Focus on completing the tabby.journal app"
            currentGoal = "- implement core data model\n- create basic UI"
            currentReflection = "Made good progress on the app structure today."
        } else if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today),
                  calendar.isDate(date, inSameDayAs: twoDaysAgo) {
            // Two days ago entry
            currentIntention = "Plan the journal app structure"
            currentGoal = "- research similar apps\n- sketch main screens\n- outline data model"
            currentReflection = "Found some great ideas from other journaling apps."
        } else {
            // Empty for other days
            currentIntention = ""
            currentGoal = ""
            currentReflection = ""
        }
    }
    
    // Simulate checking for journal entries
    private func checkForJournalEntry(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Simulate having entries for today and the previous two days
        if calendar.isDateInToday(date) {
            return true
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return true
        }
        
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today),
           calendar.isDate(date, inSameDayAs: twoDaysAgo) {
            return true
        }
        
        return false
    }
    
    // Navigate to journal view (in a real app, this would use NavigationLink or other navigation)
    private func navigateToJournalView() {
        // In the completed app, this would switch to the Journal tab and set the selected date
        // For now, it's just a placeholder
    }
}

// Individual date circle component
struct DateCircleView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool
    let dayFormatter: DateFormatter
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 4) {
            // Day of week (Mon, Tue, etc)
            Text(weekdayFormatter.string(from: date))
                .font(.system(size: 14))
                .foregroundColor(Color("CardText").opacity(0.8))
            
            // Date number with circular background
            ZStack {
                Circle()
                    .fill(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.6) : (isToday ? Color("CardBackground") : Color.clear))
                    .frame(width: 40, height: 40)
                
                // Small dot indicator for days with entries
                if hasEntry && !isSelected {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.3, blue: 0.6).opacity(0.5))
                        .frame(width: 6, height: 6)
                        .offset(y: 12)
                }
                
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? Color("CardText") : Color("CardText").opacity(0.8)))
            }
            .overlay(
                Circle()
                    .stroke(isToday && !isSelected ? Color(red: 0.4, green: 0.3, blue: 0.6) : Color.clear, lineWidth: 1.5)
                    .frame(width: 40, height: 40)
            )
            .frame(width: 40, height: 40)
            .animation(.spring(), value: isSelected)
        }
        .frame(width: 50)
        .padding(.vertical, 4)
    }
}

// Journal section preview component for calendar view
struct JournalSectionPreview: View {
    let title: String
    let icon: String
    let content: String
    let isEmpty: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("CardText"))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("CardText"))
            }
            
            // Content preview
            Text(content)
                .font(.subheadline)
                .foregroundColor(isEmpty ? Color.gray.opacity(0.7) : Color("CardText"))
                .italic(isEmpty)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
        }
        .padding(10)
        .background(Color("CardBackground").opacity(0.7))
        .cornerRadius(12)
    }
}

#Preview {
    CalendarView()
} 