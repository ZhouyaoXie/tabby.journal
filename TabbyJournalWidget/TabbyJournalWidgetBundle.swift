//
//  TabbyJournalWidgetBundle.swift
//  TabbyJournalWidget
//
//  Created by Joy Xie on 5/21/25.
//

import WidgetKit
import SwiftUI

@main
struct TabbyJournalWidgetBundle: WidgetBundle {
    var body: some Widget {
        TabbyJournalWidget()
        TabbyJournalWidgetControl()
        TabbyJournalWidgetLiveActivity()
    }
}
