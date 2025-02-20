//
//  CoinAppWidgetLiveActivity.swift
//  CoinAppWidget
//
//  Created by Petru Grigor on 13.02.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CoinAppWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CoinAppWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CoinAppWidgetAttributes.self) { context in
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

extension CoinAppWidgetAttributes {
    fileprivate static var preview: CoinAppWidgetAttributes {
        CoinAppWidgetAttributes(name: "World")
    }
}

extension CoinAppWidgetAttributes.ContentState {
    fileprivate static var smiley: CoinAppWidgetAttributes.ContentState {
        CoinAppWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CoinAppWidgetAttributes.ContentState {
         CoinAppWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CoinAppWidgetAttributes.preview) {
   CoinAppWidgetLiveActivity()
} contentStates: {
    CoinAppWidgetAttributes.ContentState.smiley
    CoinAppWidgetAttributes.ContentState.starEyes
}
