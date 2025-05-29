//
//  TabbyJournalWidget.swift
//  TabbyJournalWidget
//
//  Created by Joy Xie on 5/21/25.
//

import WidgetKit
import SwiftUI
import Intents

// MARK: - Shared Data Model (App Group UserDefaults)
struct JournalWidgetEntry: TimelineEntry {
    let date: Date
    let intention: String?
    let goal: String?
}

// Helper to fetch today's intention/goal from App Group UserDefaults
struct JournalWidgetDataProvider {
    static let appGroupId = "group.com.yourdomain.tabbyjournal" // <-- Replace with your actual App Group ID
    static let intentionKey = "widget_intention"
    static let goalKey = "widget_goal"
    
    static func fetchTodayData() -> (String?, String?) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return (nil, nil) }
        let intention = userDefaults.string(forKey: intentionKey)
        let goal = userDefaults.string(forKey: goalKey)
        return (intention, goal)
    }
}

// MARK: - Timeline Provider
struct JournalProvider: TimelineProvider {
    func placeholder(in context: Context) -> JournalWidgetEntry {
        JournalWidgetEntry(date: Date(), intention: "Set your intention", goal: "Set your goal")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (JournalWidgetEntry) -> ()) {
        let (intention, goal) = JournalWidgetDataProvider.fetchTodayData()
        let entry = JournalWidgetEntry(date: Date(), intention: intention, goal: goal)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<JournalWidgetEntry>) -> ()) {
        let (intention, goal) = JournalWidgetDataProvider.fetchTodayData()
        let entry = JournalWidgetEntry(date: Date(), intention: intention, goal: goal)
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View (Step 2/3: Refined UI)
struct JournalWidgetEntryView: View {
    var entry: JournalProvider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        ZStack {
            // Optionally, keep a very subtle gradient overlay for style
//             LinearGradient(
//                 gradient: Gradient(colors: [Color(.systemGray6), Color(red: 0.93, green: 0.90, blue: 0.98)]),
//                 startPoint: .topLeading,
//                 endPoint: .bottomTrailing
//             )
            VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 12) {
                // Intention Section
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "square.dashed")
                            .font(.system(size: family == .systemSmall ? 18 : 22, weight: .regular))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                        Text("INTENTION")
                            .font(.custom("EBGaramond-Regular", size: family == .systemSmall ? 13 : 16))
                            .foregroundColor(Color(red: 0.2, green: 0.18, blue: 0.25))
                            .textCase(.uppercase)
                    }
                    Text(entry.intention?.isEmpty == false ? entry.intention! : "Open tabby.journal to set your intention")
                        .font(.custom("EBGaramond-Regular", size: family == .systemSmall ? 13 : 15))
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
                        .lineLimit(2)
                }
                // Goals Section
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: family == .systemSmall ? 18 : 22, weight: .regular))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                        Text("GOALS")
                            .font(.custom("EBGaramond-Regular", size: family == .systemSmall ? 13 : 16))
                            .foregroundColor(Color(red: 0.2, green: 0.18, blue: 0.25))
                            .textCase(.uppercase)
                    }
                    Text(entry.goal?.isEmpty == false ? entry.goal! : "Open tabby.journal to set your goal")
                        .font(.custom("EBGaramond-Regular", size: family == .systemSmall ? 13 : 15))
                        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
                        .lineLimit(2)
                }
                Spacer(minLength: family == .systemSmall ? 2 : 8)
                // Widget Name (bottom label)
                Text("Tabby Journal")
                    .font(.custom("EBGaramond-Regular", size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(family == .systemSmall ? 2 : 10)
        }
        .containerBackground(.background, for: .widget)
    }
}

@main
struct TabbyJournalWidget: Widget {
    let kind: String = "TabbyJournalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalProvider()) { entry in
            JournalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tabby Journal")
        .description("See your daily intention or goal at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall, widget: {
    TabbyJournalWidget()
}, timeline: {
    JournalWidgetEntry(date: .now, intention: "Focus on one thing at a time", goal: "- work on LLM project for an hour; - work on tabby.journal at night")
})

#Preview(as: .systemMedium, widget: {
    TabbyJournalWidget()
}, timeline: {
    JournalWidgetEntry(date: .now, intention: "Write code", goal: "Fix all bugs")
})
