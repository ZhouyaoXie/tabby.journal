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

// MARK: - Widget Entry View (Step 1: Key UI Elements)
struct JournalWidgetEntryView: View {
    var entry: JournalProvider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Intention Section
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "square.dashed")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("INTENTION")
                        .font(.headline)
                        .textCase(.uppercase)
                    Text(entry.intention ?? "No intention set")
                        .font(.body)
                        .lineLimit(2)
                }
            }
            // Goals Section
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.seal")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GOALS")
                        .font(.headline)
                        .textCase(.uppercase)
                    Text(entry.goal ?? "No goal set")
                        .font(.body)
                        .lineLimit(2)
                }
            }
            Spacer()
            // Widget Name (placeholder)
            Text("Widget Name")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
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

#Preview(as: .systemSmall) {
    TabbyJournalWidget()
}
