//
//  TabbyJournalWidgetLiveActivity.swift
//  TabbyJournalWidget
//
//  Created by Joy Xie on 5/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TabbyJournalWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TabbyJournalWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TabbyJournalWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TabbyJournalWidgetAttributes {
    fileprivate static var preview: TabbyJournalWidgetAttributes {
        TabbyJournalWidgetAttributes(name: "World")
    }
}

extension TabbyJournalWidgetAttributes.ContentState {
    fileprivate static var smiley: TabbyJournalWidgetAttributes.ContentState {
        TabbyJournalWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TabbyJournalWidgetAttributes.ContentState {
         TabbyJournalWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TabbyJournalWidgetAttributes.preview) {
   TabbyJournalWidgetLiveActivity()
} contentStates: {
    TabbyJournalWidgetAttributes.ContentState.smiley
    TabbyJournalWidgetAttributes.ContentState.starEyes
}
