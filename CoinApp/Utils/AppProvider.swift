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
import RevenueCat

class AppProvider: ObservableObject {
    static let shared = AppProvider()
    
    private init() {
        self.showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            self.isUserSubscribed = customerInfo?.entitlements.all["pro"]?.isActive == true
        }
        AnalyticsManager.shared.setUserProperty(value: self.isUserSubscribed.description, property: "isPremiumUser")
    }
    
    func completeOnboarding() {
        AnalyticsManager.shared.logEvent(name: AnalyticsEventTutorialComplete)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        self.showOnboarding = false
    }
    
    func loadWatchList() async {
        let watchListArray = UserDefaults.standard.array(forKey: "watchList") as? [Int] ?? []
        self.watchListId = watchListArray
        var coinArray: [Coin] = []
        for id in watchListArray {
            if let coinDetails = await CMCApi.shared.getCoinDetails(id: id) {
                let coin = Coin(fromCoinDetails: coinDetails)
                coinArray.append(coin)
            }
        }
        
        DispatchQueue.main.async {
            self.coinWatchList = coinArray
        }
    }
    
    func addToWatchlist(_ coin: Coin) {
        self.watchListId.append(coin.id)
        self.coinWatchList.append(coin)
        UserDefaults.standard.set(watchListId, forKey: "watchList")
    }
    
    func removeFromWatchlist(_ coin: Coin) {
        self.watchListId.removeAll { $0 == coin.id }
        self.coinWatchList.removeAll { $0.id == coin.id }
        UserDefaults.standard.set(watchListId, forKey: "watchList")
    }
    
    private var watchListId: [Int] = []
    @Published var coinWatchList: [Coin] = []
    
    @Published var gainersList: [Coin] = []
    @Published var trendingList: [Coin] = []
    @Published var losersList: [Coin] = []
    @Published var recentlyAddedList: [Coin] = []
    @Published var mostVisitedList: [Coin] = []
    
    @Published var newsList: [NewsItem] = []
    
    @Published var showOnboarding = false
    
    @Published var path: [AppDestination] = []
    
    @Published var showPremiumFeature: Bool = false
    
    @Published var chatHistoryList: [MessageRow] = []
    
    @Published var isUserSubscribed: Bool = false
}
