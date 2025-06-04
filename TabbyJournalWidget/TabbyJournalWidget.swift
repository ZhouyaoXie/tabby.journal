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

struct MediumWidgetEntryView: View {
    var entry: JournalProvider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 12) {
                // Intention Section
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 4) {
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

struct MediumWidget: Widget {
    let kind: String = "MediumWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalProvider()) { entry in
            MediumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("tabby.journal")
        .description("See your daily intention and goal at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Reusable Small Widget View
struct SmallWidgetView: View {
    let title: String
    let content: String
    
    private func contentFontSize(for text: String) -> CGFloat {
        let count = text.count
        if count <= 45 { return 17 }
        else if count <= 70 { return 15 }
        else { return 13 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: 10) {
                    // Header
                    Text(title.uppercased())
                        .font(.custom("EBGaramond-Bold", size: 11))
                        .kerning(1.7)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    // Main content
                    Text(content)
                        .font(.custom("EBGaramond-Bold", size: contentFontSize(for: content)))
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.center)
                        .kerning(1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6)
                        .lineLimit(5)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .padding(.bottom, 8)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Intention Only Widget
struct IntentionWidgetEntryView: View {
    var entry: JournalProvider.Entry
    var body: some View {
        SmallWidgetView(
            title: "Intention",
            content: entry.intention?.isEmpty == false ? entry.intention! : "Open tabby.journal to set your intention"
        )
    }
}

struct IntentionWidget: Widget {
    let kind: String = "TabbyJournalIntentionWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalProvider()) { entry in
            IntentionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Intention (tabby.journal)")
        .description("See your daily intention at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Goal Only Widget
struct GoalWidgetEntryView: View {
    var entry: JournalProvider.Entry
    var body: some View {
        SmallWidgetView(
            title: "Goal",
            content: entry.goal?.isEmpty == false ? entry.goal! : "Open tabby.journal to set your goal"
        )
    }
}

struct GoalWidget: Widget {
    let kind: String = "TabbyJournalGoalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalProvider()) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goal (tabby.journal)")
        .description("See your daily goal at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct TabbyJournalWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MediumWidget()
        IntentionWidget()
        GoalWidget()
    }
}

// MARK: - Previews
#Preview("Intention Small", as: .systemSmall, widget: {
    IntentionWidget()
}, timeline: {
    JournalWidgetEntry(date: .now, intention: "Be present and mindful.", goal: "")
})

#Preview("Goal Small", as: .systemSmall, widget: {
    GoalWidget()
}, timeline: {
    JournalWidgetEntry(date: .now, intention: "", goal: "Finish the Tabby Journal widget UI")
})

#Preview("Medium", as: .systemMedium, widget: {
    MediumWidget()
}, timeline: {
    JournalWidgetEntry(date: .now, intention: "Write code", goal: "Fix all bugs")
})
