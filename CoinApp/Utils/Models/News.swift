//
//  News.swift
//  CoinApp
//
//  Created by Petru Grigor on 13.02.2025.
//

import Foundation

struct NewsDetails: Decodable, Identifiable {
    let id: String
    let title: String
    let url: String
    let coin: String
    let sentiment: String
    let cryptoMarketImpact: String
    let content: String
    let analysisDate: String
}

struct NewsItem: Decodable, Identifiable {
    let id: String
    let title: String
    let content: String
    let sentiment: String
    let publishedDate: String
}
