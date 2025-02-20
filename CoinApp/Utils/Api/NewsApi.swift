//
//  NewsApi.swift
//  CoinApp
//
//  Created by Petru Grigor on 13.02.2025.
//

import Foundation

class NewsApi {
    private init() {}
    
    static let shared = NewsApi()
    
    func fetchNews() async -> [NewsItem] {
        guard let url = URL(string: "https://center.codbun.com/api/news/list") else { return [] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let news = try JSONDecoder().decode([NewsItem].self, from: data)
            
            return news
        } catch {
            print("There was an error fetching data: \(error)")
            return []
        }
    }
    
    func getNewsDetails(id: String) async -> NewsDetails? {
        guard let url = URL(string: "https://center.codbun.com/api/news/\(id)") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let news = try JSONDecoder().decode(NewsDetails.self, from: data)
            
            return news
        } catch {
            print("There was an error fetching data: \(error)")
            return nil
        }
    }
}
