//
//  TabbyJournalWidget.swift
//  TabbyJournalWidget
//
//  Created by Joy Xie on 5/21/25.
//

import WidgetKit
import SwiftUI
import Intents

let intention_default_message: String = "Click here to set your intention for today!"
let goal_default_message: String = "Click here to set your goal for today!"

// MARK: - Shared Data Model (App Group UserDefaults)
struct JournalWidgetEntry: TimelineEntry {
    let date: Date
    let intention: String?
    let goal: String?
}

// Helper to fetch today's intention/goal from App Group UserDefaults
struct JournalWidgetDataProvider {
    static let appGroupId = "group.tabbyjournal"
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
    
    private var isDefaultMessage: Bool {
        content == intention_default_message || content == goal_default_message
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: 10) {
                    // Header
                    Text(title.uppercased())
                        .font(.garamondBold(size: 11))
                        .kerning(1.7)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    // Main content
                    if isDefaultMessage {
                        Text(content)
                            .font(.garamondBold(size: 13))
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .kerning(1)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .lineLimit(4)
                            .truncationMode(.tail)
                    } else {
                        Text(content)
                            .font(.garamondBold(size: contentFontSize(for: content)))
                            .foregroundColor(Color.primary)
                            .multilineTextAlignment(.center)
                            .kerning(1)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .lineLimit(4)
                            .truncationMode(.tail)
                    }
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
            content: entry.intention?.isEmpty == false ? entry.intention! : intention_default_message
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
            content: entry.goal?.isEmpty == false ? entry.goal! : goal_default_message
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
