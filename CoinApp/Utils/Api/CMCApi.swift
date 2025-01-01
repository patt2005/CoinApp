//
//  CMCApi.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI

struct MemeCoinAnalysisResponse: Codable, Hashable {
    var general_trend: String
    var indicator_analysis: String
    var chart_pattern: String
    var future_market_prediction: String
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
