//
//  CMCApi.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI

struct Coin: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let symbol: String
    let price: Double
    let selfReportedMarketCap: Double?
    let marketCap: Double
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
            let priceChange1h = try? priceContainer.decode(Double.self, forKey: .priceChange1h)
            let priceChange24h = try? priceContainer.decode(Double.self, forKey: .priceChange24h)
            let priceChange7d = try? priceContainer.decode(Double.self, forKey: .priceChange7d)
            let priceChange30d = try? priceContainer.decode(Double.self, forKey: .priceChange30d)
            let volume24h = try? priceContainer.decode(Double.self, forKey: .volume24h)
            let marketCap = try? container.decode(Double.self, forKey: .marketCap)
            let selfReportedMarketCap = try container.decode(Double.self, forKey: .selfReportedMarketCap)
            
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
}

struct MemeCoinAnalysisResponse: Codable, Hashable {
    var general_trend: String
    var indicator_analysis: String
    var chart_pattern: String
    var future_market_prediction: String
}

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
        let marketCap: Double
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

class CMCApi {
    static let shared = CMCApi()
    
    private init() {}
    
    struct ApiResponse: Decodable {
        struct ResponseList: Decodable {
            let gainerList: [Coin]
            let loserList: [Coin]
        }
        
        let data: ResponseList
    }
    
    struct PriceApiResponse: Decodable {
        struct DataWrapper: Decodable {
            let points: [String: PointData]
        }
        
        struct PointData: Decodable {
            let v: [Double]
        }
        
        let data: DataWrapper
    }
    
    struct CoinDetailsApiResponse: Decodable {
        var data: CoinDetails
    }
    
    struct SearchApiResponse: Decodable {
        let data: DataResponse
        
        struct DataResponse: Decodable {
            let pairs: [Coin]
        }
    }
    
    struct TrendingCoinsApiResponse: Decodable {
        struct DataResponse: Decodable {
            let trendingList: [Coin]
            let mostVisitedList: [Coin]
            let recentlyAddedList: [Coin]
        }
        
        let data: DataResponse
    }
    
    func getCoinPriceList(id: Int, dateRange: String) async -> [Double] {
        guard let url = URL(string: "https://api.coinmarketcap.com/data-api/v3/cryptocurrency/detail/chart?id=\(id)&range=\(dateRange.uppercased())") else { return [] }
        
        let headers = [
            "Accepts": "application/json",
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decodedData = try JSONDecoder().decode(PriceApiResponse.self, from: data)
            
            var pricePoints: [Int: Double] = [:]
            
            for (timestamp, pointData) in decodedData.data.points {
                pricePoints[Int(timestamp) ?? 0] = pointData.v.first!
            }
            
            var prices: [Double] = []
            
            for key in pricePoints.keys.sorted() {
                prices.append(pricePoints[key] ?? 0)
            }
            return prices.reversed()
        } catch {
            print("Caught an error while fetching api data: \(error.localizedDescription)")
        }
        return []
    }
    
    func getCoinFromSearchQuery(_ query: String) async -> [Coin] {
        guard let url = URL(string: "https://api.coinmarketcap.com/dexer/v3/dexer/search/main-site?keyword=\(query)&all=true") else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoded = try JSONDecoder().decode(SearchApiResponse.self, from: data)
            
            let filteredList = decoded.data.pairs.filter { coin in
                return coin.id != 0
            }
            
            var seenIds = Set<Int>()
            let uniqueFilteredList = filteredList.filter { coin in
                if seenIds.contains(coin.id) {
                    return false
                } else {
                    
                    seenIds.insert(coin.id)
                    return true
                }
            }
            
            return uniqueFilteredList
        } catch {
            print("Caught while fetching search api an error: \(error)")
        }
        return []
    }
    
    func getCoinDetails(id: Int) async -> CoinDetails? {
        guard let url = URL(string: "https://api.coinmarketcap.com/data-api/v3/cryptocurrency/detail/?id=\(id)") else { return nil }
        
        print("Coin id: \(id)")
        
        let headers = [
            "Accepts": "application/json",
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(CoinDetailsApiResponse.self, from: data)
            
            return response.data
        } catch {
            print("Caught an error while retrieving coin details from api: \(error.localizedDescription)")
        }
        return nil
    }
    
    func fetchTrendingCoins() async {
        guard let url = URL(string: "https://api.coinmarketcap.com/data-api/v3/cryptocurrency/spotlight?limit=30") else { return }
        
        let headers = [
            "Accepts": "application/json",
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Caught an error on line 106: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Data is nil.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TrendingCoinsApiResponse.self, from: data)
                DispatchQueue.main.async {
                    AppProvider.shared.recentlyAddedList = response.data.recentlyAddedList
                    AppProvider.shared.trendingList = response.data.trendingList
                    AppProvider.shared.mostVisitedList = response.data.mostVisitedList
                }
                
            } catch {
                print("Caught an error on line 491: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func fetchCoinData(dateRange: String) async {
        guard let url = URL(string: "https://api.coinmarketcap.com/data-api/v3/cryptocurrency/spotlight") else { return }
        
        let parameters: [String: Any] = [
            "rankRange": "0",
            "timeframe": dateRange,
            "convert": "USD",
            "dataType": 2,
            "limit": 30
        ]
        
        let headers = [
            "Accepts": "application/json",
        ]
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Caught an error on line 522: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Data is nil.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ApiResponse.self, from: data)
                DispatchQueue.main.async {
                    AppProvider.shared.gainersList = response.data.gainerList
                    AppProvider.shared.losersList = response.data.loserList
                }
                
            } catch {
                print("Caught an error on line 540: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}
