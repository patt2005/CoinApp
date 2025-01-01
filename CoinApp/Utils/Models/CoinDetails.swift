//
//  CoinDetails.swift
//  CoinApp
//
//  Created by Petru Grigor on 01.01.2025.
//

import Foundation
import SwiftUI

struct CoinDetails: Codable, Identifiable {
    struct Urls: Codable {
        let website: [String]
        let twitter: [String]
    }
    
    struct RelatedCoinInfo: Codable {
        let id: Int
        let name: String
        let price: Double
        let priceChangePercentage24h: Double
        
        var imageUrl: String {
            return "https://s2.coinmarketcap.com/static/img/coins/128x128/\(id).png"
        }
    }
    
    struct ContractInfo: Codable {
        let contractId: Int
        let contractAddress: String
        let contractPlatform: String
        let contractExplorerUrl: String
        
        var imageUrl: String {
            return "https://s2.coinmarketcap.com/static/img/coins/128x128/\(contractId).png"
        }
    }
    
    struct Holders: Codable {
        struct HolderInfo: Codable {
            let address: String
            let balance: Double
            let share: Double
        }
        
        let holderList: [HolderInfo]
        let topTenHolderRatio: Double
        let topTwentyHolderRatio: Double
        let topFiftyHolderRatio: Double
        let topHundredHolderRatio: Double
    }
    
    struct Statistics: Codable {
        let price: Double
        let fullyDilutedMarketCap: Double
        let totalSupply: Double
        let rank: Int
        let priceChangePercentage1h: Double
        let priceChangePercentage24h: Double
        let priceChangePercentage7d: Double
        let priceChangePercentage30d: Double
        let priceChangePercentage1y: Double
    }
    
    let id: Int
    let name: String
    let symbol: String
    let description: String
    let dateAdded: Date
    let urls: Urls
    let volume: Double
    let statistics: Statistics
    let platforms: [ContractInfo]?
    let holders: Holders?
    
    func getPriceChangeText(_ dateRange: String) -> some View {
        let priceChangePercentage: Double
        switch dateRange {
        case "1h":
            priceChangePercentage = statistics.priceChangePercentage1h
        case "1d":
            priceChangePercentage = statistics.priceChangePercentage24h
        case "7d":
            priceChangePercentage = statistics.priceChangePercentage7d
        case "1m":
            priceChangePercentage = statistics.priceChangePercentage30d
        case "1y":
            priceChangePercentage = statistics.priceChangePercentage1y
        default:
            priceChangePercentage = 0
        }
        
        if priceChangePercentage < 0 {
            return HStack(alignment: .center, spacing: 1) {
                Text("▾")
                    .font(.title)
                    .foregroundStyle(.red)
                    .padding(.bottom, 2)
                Text("\(String(format: "%.2f", priceChangePercentage))%")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        } else {
            return HStack(alignment: .center, spacing: 1) {
                Text("▴")
                    .font(.title)
                    .foregroundStyle(.green)
                    .padding(.bottom, 2)
                Text("\(String(format: "%.2f", priceChangePercentage))%")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.description = try container.decode(String.self, forKey: .description)
        let stringDate = try container.decode(String.self, forKey: .dateAdded)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        self.dateAdded = dateFormatter.date(from: stringDate) ?? Date.now
        self.urls = try container.decode(Urls.self, forKey: .urls)
        self.volume = try container.decode(Double.self, forKey: .volume)
        self.statistics = try container.decode(Statistics.self, forKey: .statistics)
        self.platforms = try? container.decode([ContractInfo].self, forKey: .platforms)
        self.holders = try? container.decode(Holders.self, forKey: .holders)
    }
}
