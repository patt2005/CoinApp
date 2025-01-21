//
//  UserApi.swift
//  CoinApp
//
//  Created by Petru Grigor on 17.01.2025.
//

import Foundation

class UserApi {
    static let shared = UserApi()
    
    private init() {}
    
    var userId: String = ""
    
    func registerUser(withId id: String) async throws {
        guard let url = URL(string: "https://meme.codbun.com/User/add-user/?fcmId=\(id)") else { throw URLError(.badURL) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Success: \(httpResponse.statusCode)")
            } else {
                throw URLError(.badURL)
            }
        } else {
            print("❌ Invalid response received")
        }
    }
    
    func addToWatchlist(coinId: Int) async throws {
        guard let url = URL(string: "https://meme.codbun.com/User/add-to-watchlist/?fcmId=\(userId)&coinId=\(coinId)") else { throw URLError(.badURL) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Success: \(httpResponse.statusCode)")
            } else {
                throw URLError(.badURL)
            }
        } else {
            print("❌ Invalid response received")
        }
    }
    
    func removeFromWatchlist(coinId: Int) async throws {
        guard let url = URL(string: "https://meme.codbun.com/User/remove-from-watchlist/?fcmId=\(userId)&coinId=\(coinId)") else { throw URLError(.badURL) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Success: \(httpResponse.statusCode)")
            } else {
                throw URLError(.badURL)
            }
        } else {
            print("❌ Invalid response received")
        }
    }
}
