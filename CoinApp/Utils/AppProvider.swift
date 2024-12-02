//
//  AppProvider.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI

class AppProvider: ObservableObject {
    static let instance = AppProvider()
    
    private init() {}
    
    @Published var gainersList: [Coin] = []
    @Published var trendingList: [Coin] = []
    @Published var losersList: [Coin] = []
    @Published var recentlyAddedList: [Coin] = []
    @Published var mostVisitedList: [Coin] = []
}
