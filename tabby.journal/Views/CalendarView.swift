import SwiftUI
import CoreData
import Combine
import Foundation

// Import the shared font extension
// (Assume Font+Garamond.swift is in the module)

struct CalendarView: View {
    // Constants for date range
    private let calendarStartDate: Date = {
        var components = DateComponents()
        components.year = 1999
        components.month = 07
        components.day = 15
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private let calendarEndDate: Date = {
        var components = DateComponents()
        components.year = 2050
        components.month = 12
        components.day = 31
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    // Virtualization parameters
    private let visibleDayWindow: Int = 365 // Show about a year of dates at a time
    private let visibleDayBuffer: Int = 90  // Buffer of 3 months on each side
    private var totalDaysInRange: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendarStartDate, to: calendarEndDate)
        return components.day ?? 18000 // Fallback to approximate number
    }
    
    @State private var selectedDate: Date = Date()
    @State private var visibleDateRange: ClosedRange<Date> = Date()...Date()
    @State private var displayDates: [Date] = []
    @State private var centerVisibleIndex: Int = 0 // Current center of visible window
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    
    // Journal entry data for the selected date
    @State private var currentIntention: String = ""
    @State private var currentGoal: String = ""
    @State private var currentReflection: String = ""
    @State private var hasLoadedData: Bool = false
    
    // --- Inline Editing State ---
    @State private var isEditingIntention: Bool = false
    @State private var isEditingGoal: Bool = false
    @State private var isEditingReflection: Bool = false
    @State private var editedIntention: String = ""
    @State private var editedGoal: String = ""
    @State private var editedReflection: String = ""
    
    // Format for the header (Mon, Aug 17)
    private let dateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d, yyyy"
        return formatter
    }()
    
    // Format for the day number (17)
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    // Format for the month (Aug)
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    // Core Data operations
    private func fetchJournalEntry(for date: Date) -> NSManagedObject? {
        // Use direct Core Data queries since we don't have access to CoreDataManager
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching journal entry: \(error)")
            return nil
        }
    }
    
    private func fetchJournalEntries(from startDate: Date, to endDate: Date) -> [NSManagedObject] {
        // Use direct Core Data queries
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfStartDate as NSDate, endOfEndDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching journal entries: \(error)")
            return []
        }
    }
    
    private func getEntryValues(_ entry: NSManagedObject) -> (intention: String?, goal: String?, reflection: String?) {
        let intention = entry.value(forKey: "intention") as? String
        let goal = entry.value(forKey: "goal") as? String
        let reflection = entry.value(forKey: "reflection") as? String
        
        return (intention, goal, reflection)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PageBackground").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 8) {
                    // Header and date picker with fixed height
                    VStack(spacing: 8) {
                        // Spacer().frame(height: 12)
                        // Selected date display
                        HStack {
                            Text(dateHeaderFormatter.string(from: selectedDate))
                                .font(.garamondBold(size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(Color("CardText"))
                                // .padding(.top, 32)
                                // .padding(.leading, 16)
                                // .padding(.bottom, 8)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    selectedDate = Date()
                                    updateVisibleDates(around: selectedDate)
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(Color("CardText"))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 32)
                        // .padding(.leading, 16)
                        .padding(.bottom, 8)
                        // Date navigation section
                        HStack {
                            Button(action: {
                                withAnimation {
                                    if let previousMonth = getFirstDayOfPreviousMonth(from: selectedDate) {
                                        selectedDate = previousMonth
                                        updateVisibleDates(around: selectedDate)
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(Color("CardText"))
                                    .padding(8)
                                    .background(Circle().fill(Color("CardBackground")))
                            }
                            Spacer()
                            Text(formatMonthYear(selectedDate))
                                .font(.garamondBold(size: 20))
                                .foregroundColor(Color("CardText"))
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    if let nextMonth = getFirstDayOfNextMonth(from: selectedDate) {
                                        selectedDate = nextMonth
                                        updateVisibleDates(around: selectedDate)
                                    }
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
                                LazyHStack(spacing: 16) {
                                    ForEach(displayDates, id: \.self) { date in
                                        DateCircleView(
                                            date: date,
                                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                            isToday: Calendar.current.isDateInToday(date),
                                            hasEntry: checkForJournalEntry(date),
                                            dayFormatter: dayFormatter,
                                            monthFormatter: monthFormatter,
                                            showMonth: shouldShowMonth(for: date)
                                        )
                                        .id(formatDateID(date))
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedDate = date
                                                loadJournalEntry(for: date)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    updateVisibleDates(around: selectedDate)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation {
                                            scrollView.scrollTo(formatDateID(selectedDate), anchor: .center)
                                        }
                                    }
                                }
                            }
                            .onChange(of: selectedDate) { newDate in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollView.scrollTo(formatDateID(newDate), anchor: .center)
                                    }
                                }
                                loadJournalEntry(for: newDate)
                            }
                            .onChange(of: displayDates) { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollView.scrollTo(formatDateID(selectedDate), anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color("CardBackground").opacity(0.6))
                    .frame(height:220) // Fixed height for header/date picker

                    // Journal entry display area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Intention Section
                            JournalSectionPreview(
                                title: "Intention",
                                icon: "house.fill",
                                content: isEditingIntention ? editedIntention : (currentIntention.isEmpty ? "" : currentIntention),
                                isEmpty: currentIntention.isEmpty,
                                isEditing: isEditingIntention,
                                onEdit: {
                                    editedIntention = currentIntention
                                    isEditingIntention = true
                                },
                                onComplete: {
                                    saveEditedSection(section: "intention", text: editedIntention)
                                    isEditingIntention = false
                                },
                                onTextChange: { newText in
                                    editedIntention = newText
                                }
                            )
                            // Goal Section
                            JournalSectionPreview(
                                title: "Goal",
                                icon: "checkmark.seal.fill",
                                content: isEditingGoal ? editedGoal : (currentGoal.isEmpty ? "" : currentGoal),
                                isEmpty: currentGoal.isEmpty,
                                isEditing: isEditingGoal,
                                onEdit: {
                                    editedGoal = currentGoal
                                    isEditingGoal = true
                                },
                                onComplete: {
                                    saveEditedSection(section: "goal", text: editedGoal)
                                    isEditingGoal = false
                                },
                                onTextChange: { newText in
                                    editedGoal = newText
                                }
                            )
                            // Reflection Section
                            JournalSectionPreview(
                                title: "Reflection",
                                icon: "book.closed.fill",
                                content: isEditingReflection ? editedReflection : (currentReflection.isEmpty ? "" : currentReflection),
                                isEmpty: currentReflection.isEmpty,
                                isEditing: isEditingReflection,
                                onEdit: {
                                    editedReflection = currentReflection
                                    isEditingReflection = true
                                },
                                onComplete: {
                                    saveEditedSection(section: "reflection", text: editedReflection)
                                    isEditingReflection = false
                                },
                                onTextChange: { newText in
                                    editedReflection = newText
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("")
            // .navigationTitle("🐾")
            // #if os(iOS)
            // .navigationBarTitleDisplayMode(.inline)
            // #endif
            .onAppear {
                print("CalendarView appeared, preparing to refresh data")
                
                // Initialize the date window with today at the center
                if displayDates.isEmpty {
                    updateVisibleDates(around: Date())
                }
                
                loadJournalEntry(for: selectedDate)
            }
            .onChange(of: displayDates) { _ in
                loadJournalEntry(for: selectedDate)
            }
            .onChange(of: appState.journalUpdateId) { newId in
                print("===== CALENDAR REFRESH =====")
                print("Detected AppState update with ID: \(newId)")
                print("Timestamp: \(appState.lastJournalUpdate)")
                print("Refreshing calendar data...")
                
                loadJournalEntry(for: selectedDate)
                
                print("Calendar refresh complete")
                print("===========================")
            }
        }
    }
    
    // Calculates the index for a specific date relative to the start date
    private func indexForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendarStartDate, to: date)
        return max(0, components.day ?? 0)
    }
    
    // Gets the date for a specific index
    private func dateForIndex(_ index: Int) -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: index, to: calendarStartDate)
    }
    
    // Check if date is near the edge of our current date window
    private func isDateNearEdge(_ date: Date) -> Bool {
        let index = indexForDate(date)
        let windowStart = centerVisibleIndex - (visibleDayWindow / 2)
        let windowEnd = centerVisibleIndex + (visibleDayWindow / 2)
        
        // Check if within buffer of either edge
        return index < (windowStart + visibleDayBuffer) || index > (windowEnd - visibleDayBuffer)
    }
    
    // Update visible dates centered around a specific date
    private func updateVisibleDates(around centerDate: Date) {
        print("Updating visible dates around: \(dateHeaderFormatter.string(from: centerDate))")
        
        // Ensure date is within valid range
        let validCenterDate = min(max(centerDate, calendarStartDate), calendarEndDate)
        
        // Calculate the index for the center date
        let centerIndex = indexForDate(validCenterDate)
        centerVisibleIndex = centerIndex
        
        // Calculate start and end indices
        let halfWindow = visibleDayWindow / 2
        let startIndex = max(0, centerIndex - halfWindow)
        let endIndex = min(totalDaysInRange, centerIndex + halfWindow)
        
        // Update the visible date range
        if let startDate = dateForIndex(startIndex),
           let endDate = dateForIndex(endIndex) {
            visibleDateRange = startDate...endDate
            
            // Generate only the dates we need to display
            var dates: [Date] = []
            for i in startIndex...endIndex {
                if let date = dateForIndex(i) {
                    dates.append(date)
                }
            }
            
            print("Generated \(dates.count) dates from \(dateHeaderFormatter.string(from: dates.first!)) to \(dateHeaderFormatter.string(from: dates.last!))")
            displayDates = dates
        }
    }
    
    // Check if we should show the month label (first day of month or first visible date)
    private func shouldShowMonth(for date: Date) -> Bool {
        let calendar = Calendar.current
        let isFirstDayOfMonth = calendar.component(.day, from: date) == 1
        
        // Also show month for the first visible date
        if let firstDate = displayDates.first, calendar.isDate(date, inSameDayAs: firstDate) {
            return true
        }
        
        return isFirstDayOfMonth
    }
    
    // Helper to format month and year (e.g., "August 2023")
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Get the first day of the previous month from a given date
    private func getFirstDayOfPreviousMonth(from date: Date) -> Date? {
        let calendar = Calendar.current
        
        // Get the first day of the current month
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.day = 1
        
        guard let firstDayOfCurrentMonth = calendar.date(from: components) else {
            return nil
        }
        
        // Subtract one day to get the last day of the previous month
        guard let lastDayOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: firstDayOfCurrentMonth) else {
            return nil
        }
        
        // Get the first day of the previous month
        components = calendar.dateComponents([.year, .month, .day], from: lastDayOfPreviousMonth)
        components.day = 1
        
        let firstDayOfPreviousMonth = calendar.date(from: components)
        
        // Ensure we don't go before our minimum date
        if let result = firstDayOfPreviousMonth, result < calendarStartDate {
            return calendarStartDate
        }
        
        return firstDayOfPreviousMonth
    }
    
    // Get the first day of the next month from a given date
    private func getFirstDayOfNextMonth(from date: Date) -> Date? {
        let calendar = Calendar.current
        
        // Get current month and year
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Move to next month, day 1
        if components.month == 12 {
            components.month = 1
            components.year! += 1
        } else {
            components.month! += 1
        }
        components.day = 1
        
        let firstDayOfNextMonth = calendar.date(from: components)
        
        // Ensure we don't go beyond our maximum date
        if let result = firstDayOfNextMonth, result > calendarEndDate {
            return calendarEndDate
        }
        
        return firstDayOfNextMonth
    }
    
    // Load journal entry for the selected date from Core Data
    private func loadJournalEntry(for date: Date) {
        if let entry = fetchJournalEntry(for: date) {
            // Get values from Core Data
            let values = getEntryValues(entry)
            
            // Update our state values
            currentIntention = values.intention ?? ""
            currentGoal = values.goal ?? ""
            currentReflection = values.reflection ?? ""
        } else {
            // No entry exists for this date
            currentIntention = ""
            currentGoal = ""
            currentReflection = ""
        }
        
        hasLoadedData = true
    }
    
    // Check if a journal entry exists for a date
    private func checkForJournalEntry(_ date: Date) -> Bool {
        return fetchJournalEntry(for: date) != nil
    }
    
    // Navigate to journal view
    private func navigateToJournalView() {
        // In a real implementation, this would use TabView selection to switch tabs
        // For now, it's just a placeholder
        // TODO: Implement tab switching logic
    }
    
    // Format date to a reliable string ID
    private func formatDateID(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
    
    // --- Save edited section to Core Data ---
    private func saveEditedSection(section: String, text: String) {
        // Fetch or create the journal entry for the selected date
        let calendar = Calendar.current
        let startOfDay: Date = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.fetchLimit = 1
        do {
            let results = try viewContext.fetch(fetchRequest)
            let entry: NSManagedObject
            if let existing = results.first {
                entry = existing
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "JournalEntry", in: viewContext)!
                entry = NSManagedObject(entity: entity, insertInto: viewContext)
                entry.setValue(startOfDay, forKey: "date")
            }
            entry.setValue(text, forKey: section)
            try viewContext.save()
            // Update local state
            switch section {
            case "intention": currentIntention = text
            case "goal": currentGoal = text
            case "reflection": currentReflection = text
            default: break
            }
        } catch {
            print("Error saving edited section: \(error)")
        }
    }
}

// Individual date circle component
struct DateCircleView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool
    let dayFormatter: DateFormatter
    let monthFormatter: DateFormatter
    let showMonth: Bool
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month if it should be shown
            if showMonth {
                Text(monthFormatter.string(from: date))
                    .font(.garamond(size: 12))
                    .foregroundColor(Color("CardText").opacity(0.9))
                    .padding(.bottom, 2)
            } else {
                // Placeholder to maintain spacing
                Text(" ")
                    .font(.garamond(size: 12))
                    .opacity(0)
            }
            
            // Day of week (Mon, Tue, etc)
            Text(weekdayFormatter.string(from: date))
                .font(.garamond(size: 14))
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
                        .offset(y: 16)
                }
                
                Text(dayFormatter.string(from: date))
                    .font(.garamond(size: 20))
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
    }
}

// Journal section preview component for calendar view
struct JournalSectionPreview: View {
    let title: String
    let icon: String
    let content: String
    let isEmpty: Bool
    let isEditing: Bool
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onTextChange: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("CardText"))
                Text(title)
                    .font(.garamondBold(size: 20))
                    .foregroundColor(Color("CardText"))
                Spacer()
                if isEditing {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onComplete()
                    }) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                    }
                } else {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onEdit()
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                    }
                }
            }
            if isEditing {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .opacity(0.95)
                    TextEditor(text: Binding(
                        get: { content },
                        set: { onTextChange($0) }
                    ))
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(4)
                    .font(.garamond(size: 16))
                    .background(Color.white)
                    .foregroundColor(Color("CardText"))
                    .cornerRadius(12)
                    .colorScheme(.light)  // Force light mode
                }
                .padding(6)
            } else {
                Text(content)
                    .font(.garamond(size: 16))
                    .foregroundColor(isEmpty ? Color.gray.opacity(0.7) : Color("CardText"))
                    .font(.garamondItalic(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
            }
        }
        .padding(10)
        .background(Color("CardBackground").opacity(0.7))
        .cornerRadius(12)
        .animation(.easeInOut, value: isEditing)
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}

// Helper for preview
struct PersistenceController {
    // Shared instance for the app
    static let shared = PersistenceController()
    
    // Preview instance with sample data
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create 10 sample entries
        let viewContext = controller.container.viewContext
        
        // Sample data for past week
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in -6...0 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let newEntry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: viewContext)
                newEntry.setValue(date, forKey: "date")
                newEntry.setValue("Preview intention for \(dayOffset)", forKey: "intention")
                newEntry.setValue("Preview goal for \(dayOffset)", forKey: "goal")
                
                // Only add reflection for past days
                if dayOffset < 0 {
                    newEntry.setValue("Preview reflection for \(dayOffset)", forKey: "reflection")
                }
            }
        }
        
        // Save the context
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error creating preview data: \(nsError)")
        }
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // Create an in-memory store if specified
        container = NSPersistentContainer(name: "JournalEntry")
        
        if inMemory {
            // Use in-memory store type
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("Error loading persistent stores: \(error)")
            }
        }
        
        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
