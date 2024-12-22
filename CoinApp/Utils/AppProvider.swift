//
//  AppProvider.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI
import FirebaseAnalytics
import FirebaseMessaging

class AppProvider: ObservableObject {
    static let shared = AppProvider()
    
    private init() {
        self.showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        Messaging.messaging().subscribe(toTopic: "main") { error in
            print("Subscribed to main topic")
        }
        AnalyticsManager.shared.logEvent(name: AnalyticsEventTutorialComplete)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        self.showOnboarding = false
    }
    
    @Published var gainersList: [Coin] = []
    @Published var trendingList: [Coin] = []
    @Published var losersList: [Coin] = []
    @Published var recentlyAddedList: [Coin] = []
    @Published var mostVisitedList: [Coin] = []
    
    @Published var showPaywall: Bool = false
    @Published var showOnboarding = false

    @Published var path: [AppDestination] = []
    
    @Published var chatHistoryList: [MessageRow] = []
}
