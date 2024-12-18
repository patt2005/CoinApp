//
//  UserViewModel.swift
//  CoinApp
//
//  Created by Petru Grigor on 02.12.2024.
//

import Foundation
import RevenueCat

class UserViewModel: ObservableObject {
    @Published var isUserSubscribed: Bool = false
    
    init() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            self.isUserSubscribed = customerInfo?.entitlements.all["pro"]?.isActive == true
        }
        AnalyticsManager.shared.setUserProperty(value: self.isUserSubscribed.description, property: "isPremiumUser")
    }
}
