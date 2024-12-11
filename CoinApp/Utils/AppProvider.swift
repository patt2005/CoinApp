//
//  AppProvider.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI
import FirebaseAnalytics

class AppProvider: ObservableObject {
    static let instance = AppProvider()
    
    private init() {
        self.showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
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
}
