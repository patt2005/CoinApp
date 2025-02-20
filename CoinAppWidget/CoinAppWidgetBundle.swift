//
//  CoinAppWidgetBundle.swift
//  CoinAppWidget
//
//  Created by Petru Grigor on 13.02.2025.
//

import WidgetKit
import SwiftUI

@main
struct CoinAppWidgetBundle: WidgetBundle {
    var body: some Widget {
        CoinAppWidget()
        CoinAppWidgetControl()
        CoinAppWidgetLiveActivity()
    }
}
