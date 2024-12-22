//
//  AnalyticsManager.swift
//  CoinApp
//
//  Created by Petru Grigor on 10.12.2024.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    func logEvent(name: String, params: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: params)
    }
    
    func setUserId(userId: String) {
        Analytics.setUserID(userId)
    }
    
    func setUserProperty(value: String?, property: String) {
        Analytics.setUserProperty(value, forName: property)
    }
}
