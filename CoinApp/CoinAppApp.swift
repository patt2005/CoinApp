//
//  CoinAppApp.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import SwiftUI
import RevenueCat

@main
struct CoinAppApp: App {
    @StateObject var userViewModel: UserViewModel = UserViewModel()
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_uJbYFaiwBZHJPOMizXgSqOvSqbV")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
        }
    }
}
