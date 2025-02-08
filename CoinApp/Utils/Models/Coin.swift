//
//  Coin.swift
//  CoinApp
//
//  Created by Petru Grigor on 01.01.2025.
//

import Foundation
import SwiftUI

struct Coin: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let symbol: String
    let price: Double
    let selfReportedMarketCap: Double?
    let marketCap: Double?
    let priceChange1h: Double?
    let priceChange24h: Double
    let priceChange7d: Double?
    let priceChange30d: Double?
    let volume24h: Double
    
    var imageUrl: String {
        return "https://s2.coinmarketcap.com/static/img/coins/128x128/\(id).png"
    }
    
    func getPriceChangeText(_ dateRange: String) -> some View {
        let priceChangePercentage: Double
        switch dateRange {
        case "1h":
            priceChangePercentage = priceChange1h ?? 0
        case "24h":
            priceChangePercentage = priceChange24h
        case "7d":
            priceChangePercentage = priceChange7d ?? 0
        case "30d":
            priceChangePercentage = priceChange30d ?? 0
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
    
    private enum CodingKeys: CodingKey {
        case id
        case name
        case symbol
        case selfReportedMarketCap
        case marketCap
        case priceChange
    }
    
    private enum PriceChangeKeys: CodingKey {
        case price
        case priceChange1h
        case priceChange24h
        case priceChange7d
        case priceChange30d
        case volume24h
    }
    
    private enum PairKeys: String, CodingKey {
        case baseToken
        case name = "baseTokenName"
        case symbol = "baseTokenSymbol"
        case price = "priceUsd"
        case priceChange24h
        case volume24h
        case selfReportedMarketCap
        case marketCap
    }
    
    private enum BaseTokenKeys: String, CodingKey {
        case id
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(Int.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let symbol = try container.decode(String.self, forKey: .symbol)
            let priceContainer = try container.nestedContainer(keyedBy: PriceChangeKeys.self, forKey: .priceChange)
            let price = try priceContainer.decode(Double.self, forKey: .price)
            let priceChange1h = try? priceContainer.decodeIfPresent(Double.self, forKey: .priceChange1h)
            let priceChange24h = try? priceContainer.decode(Double.self, forKey: .priceChange24h)
            let priceChange7d = try? priceContainer.decode(Double.self, forKey: .priceChange7d)
            let priceChange30d = try? priceContainer.decode(Double.self, forKey: .priceChange30d)
            let volume24h = try? priceContainer.decode(Double.self, forKey: .volume24h)
            let marketCap = try? container.decodeIfPresent(Double.self, forKey: .marketCap)
            let selfReportedMarketCap = try? container.decodeIfPresent(Double.self, forKey: .selfReportedMarketCap)
            
            self.id = id
            self.name = name
            self.symbol = symbol
            self.price = price
            self.priceChange1h = priceChange1h
            self.priceChange24h = priceChange24h ?? 0
            self.priceChange7d = priceChange7d
            self.priceChange30d = priceChange30d
            self.volume24h = volume24h ?? 0.0
            self.marketCap = marketCap ?? 0.0
            self.selfReportedMarketCap = selfReportedMarketCap
        } catch {
            let container = try decoder.container(keyedBy: PairKeys.self)
            let baseTokenContainer = try container.nestedContainer(keyedBy: BaseTokenKeys.self, forKey: .baseToken)
            
            let baseTokenId = try? baseTokenContainer.decodeIfPresent(String.self, forKey: .id)
            let intBaseTokenId = Int(baseTokenId ?? "0") ?? 0
            
            let name = try container.decode(String.self, forKey: .name)
            let symbol = try container.decode(String.self, forKey: .symbol)
            let price = try Double(container.decode(String.self, forKey: .price)) ?? 0.0
            let priceChange24h = try Double(container.decode(String.self, forKey: .priceChange24h)) ?? 0.0
            let volume24h = try Double(container.decode(String.self, forKey: .volume24h)) ?? 0.0
            let selfReportedMarketCap = try? container.decode(Double.self, forKey: .selfReportedMarketCap)
            let marketcap = try? container.decode(String.self, forKey: .marketCap)
            
            self.id = intBaseTokenId
            self.name = name
            self.symbol = symbol
            self.price = price
            self.priceChange1h = nil
            self.priceChange24h = priceChange24h
            self.priceChange7d = nil
            self.priceChange30d = nil
            self.volume24h = volume24h
            self.selfReportedMarketCap = selfReportedMarketCap
            self.marketCap = Double(marketcap ?? "0.0") ?? 0.0
        }
    }
    
    init (fromCoinDetails details: CoinDetails) {
        self.id = details.id
        self.name = details.name
        self.selfReportedMarketCap = nil
        self.symbol = details.symbol
        self.price = details.statistics.price
        self.volume24h = details.volume
        self.priceChange24h = details.statistics.priceChangePercentage24h
        self.marketCap = details.statistics.fullyDilutedMarketCap
        self.priceChange1h = nil
        self.priceChange7d = nil
        self.priceChange30d = nil
    }
    
    init (fromNotificationData data: [AnyHashable : Any]) {
        self.id = Int(data["id"] as! String) ?? 1
        self.symbol = data["symbol"] as! String
        self.name = data["name"] as! String
        self.price = Double(data["price"] as! String) ?? 0
        self.marketCap = Double(data["marketCap"] as! String) ?? 0
        self.priceChange1h = nil
        self.volume24h = Double(data["volume24h"] as! String) ?? 0
        self.priceChange24h = Double(data["priceChange24h"] as! String) ?? 0
        self.priceChange7d = nil
        self.priceChange30d = nil
        self.selfReportedMarketCap = Double(data["marketCap"] as! String) ?? 0
    }
}
