//
//  OpenAiApi.swift
//  CoinApp
//
//  Created by Petru Grigor on 17.12.2024.
//

import Foundation
import SwiftUI

class OpenAiApi {
    struct OpenAIAPIResponse: Codable {
        var choices: [Choice]
        
        struct Choice: Codable {
            var message: Message
            struct Message: Codable {
                var content: String
            }
        }
    }
    
    enum ApiAnalysisError: Error {
        case invalidData
        case invalidResponse
    }
    
    struct CompletionResponse: Decodable {
        struct Choice: Decodable {
            let delta: Delta
        }
        
        struct Delta: Decodable {
            let content: String
        }
        
        let choices: [Choice]
    }
    
    static let shared = OpenAiApi()
    
    private init() {}
    
    private func cleanResponseText(_ text: String) -> String {
        var cleanedText = text
        
        cleanedText = cleanedText.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "\\*(.*?)\\*", with: "$1", options: .regularExpression)
        
        cleanedText = cleanedText.replacingOccurrences(of: "###\\s*", with: "", options: .regularExpression)
        
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^-\\s", with: "• ", options: .regularExpression)
        
        return cleanedText
    }
    
    private let systemPrompt = """
                You are a professional trader specializing in meme coins and cryptocurrency markets. 
                You have extensive experience analyzing chart patterns, market trends, and identifying key factors that drive meme coin behavior. 
                Your expertise includes understanding the volatile nature of meme coins, the impact of social media trends, community-driven market moves, and the role of celebrity endorsements. 
                When analyzing charts, you focus on identifying early trends, breakout points, pump-and-dump patterns, and the influence of social sentiment. 
                You are able to analyze a chart to determine which meme coin it is, providing detailed insights about its potential price movements, and the likelihood of continued hype or market correction. 
                Your goal is to provide actionable insights on the meme coin, with a focus on spotting opportunities, understanding volatility, and predicting potential future movements.
    """
    
    private let jsonParams = """
                        Please return your analysis in the following JSON format with the following sections:
                        
                        - **"general_trend"**: A detailed analysis of the current trend, whether it’s bullish, bearish, or neutral. Include key trend points like price movements, support, and resistance levels.
                        
                        - **"indicator_analysis"**: A breakdown of technical indicators used in the analysis. This may include moving averages, RSI, MACD, Bollinger Bands, etc. Provide insights into whether these indicators support the trend or signal a reversal.
                        
                        - **"chart_pattern"**: Analyze the chart for any recognizable patterns, such as triangles, head and shoulders, or double tops/bottoms. Mention if the chart pattern indicates a continuation or reversal.
                        
                        - **"future_market_prediction"**: A forecast of the potential market movements. Discuss any predicted future price movements, possible breakouts or breakdowns, or potential consolidation areas.
    """
    
    private let sampleJsonPrompt = """
                {
                    "general_trend": "The current trend is neutral, as the coin has been experiencing a sideways movement over the past few days. Price action has not shown strong directional momentum.",
                    "indicator_analysis": "The RSI is currently at 50, indicating a neutral market sentiment. The MACD is flat, and there are no strong buy or sell signals. Bollinger Bands are showing low volatility, suggesting consolidation.",
                    "chart_pattern": "There are no significant patterns observed in the chart. The price action is range-bound, and there is no clear breakout or breakdown signal at the moment.",
                    "future_market_prediction": "In the short term, the market is expected to remain relatively stable. However, any new market catalyst, such as news or social sentiment, could drive price movement in either direction."
                }
    """
    
    func analyzeChartImage(image: UIImage) async throws -> MemeCoinAnalysisResponse {
        guard let base64Image = convertImageToBase64(image: image) else {
            print("Failed to convert image to Base64")
            throw ApiAnalysisError.invalidData
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(AppConstants.openAiApiKey)"
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "developer",
                    "content": """
                        \(systemPrompt)
                    
                        \(jsonParams)
                    
                        If the provided image cannot be loaded or there is an error with it, please return a **general analysis** of the meme coin and market in the same format (with appropriate dummy content) as shown below:
                    
                        \(sampleJsonPrompt)
                    """,
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "Analyze the chart and provide key insights, including the meme coin's general trend, indicator analysis, chart pattern, and future market prediction:"],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Error: Unable to serialize JSON")
            throw ApiAnalysisError.invalidData
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let responseObject = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
            
            var messageContent = responseObject.choices.first?.message.content ?? ""
            
            if messageContent.hasPrefix("```json") {
                messageContent = messageContent.replacingOccurrences(of: "```json", with: "")
            }
            if messageContent.hasSuffix("```") {
                messageContent = messageContent.replacingOccurrences(of: "```", with: "")
            }
            if let jsonData = messageContent.data(using: .utf8) {
                let analysis = try JSONDecoder().decode(MemeCoinAnalysisResponse.self, from: jsonData)
                
                return analysis
            } else {
                print("Error: Unable to parse cleaned JSON string")
                
                throw ApiAnalysisError.invalidData
            }
        } catch {
            print("Caught an error: \(error.localizedDescription)")
            
            throw ApiAnalysisError.invalidData
        }
    }
    
    func getCoinAnalysis(coin: Coin, priceList: [Double], dateRange: String, marketCap: Double, priceChange: Double) async throws -> MemeCoinAnalysisResponse {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(AppConstants.openAiApiKey)"
        ]
        
        let priceListFormatted = priceList.enumerated().map { index, price in
            "\"\(index + 1)\": \(price)"
        }.joined(separator: ", ")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "developer",
                    "content": """
                        \(systemPrompt)
                    
                        \(jsonParams)
                    
                        If insufficient data is provided, return a general market analysis in the same JSON format.
                    
                        \(sampleJsonPrompt)
                    """,
                ],
                [
                    "role": "user",
                    "content": """
                        Analyze the following meme coin information and historical price data:
                        - Coin Name: \(coin.name)
                        - Symbol: \(coin.symbol)
                        - Current Price: \(coin.price)
                        - Price Change (\(dateRange): \(priceChange)%
                        - Volume (24h): $\(coin.volume24h)
                        - Price Data (ordered by timestamp): {\(priceListFormatted)}
                        - Date Range: \(dateRange)
                        - Market Cap: \(marketCap)
                    """
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Error: Unable to serialize JSON")
            throw ApiAnalysisError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let responseObject = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
            
            var messageContent = responseObject.choices.first?.message.content ?? ""
            
            if messageContent.hasPrefix("```json") {
                messageContent = messageContent.replacingOccurrences(of: "```json", with: "")
            }
            if messageContent.hasSuffix("```") {
                messageContent = messageContent.replacingOccurrences(of: "```", with: "")
            }
            
            if let jsonData = messageContent.data(using: .utf8) {
                let analysis = try JSONDecoder().decode(MemeCoinAnalysisResponse.self, from: jsonData)
                
                return analysis
            } else {
                print("Error: Unable to parse cleaned JSON string")
                throw ApiAnalysisError.invalidData
            }
        } catch {
            print("Caught an error: \(error.localizedDescription)")
            throw ApiAnalysisError.invalidData
        }
    }
    
    func getChatResponse(_ message: String, imagesList: [String]) async throws -> AsyncThrowingStream<String, Error> {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(AppConstants.openAiApiKey)"
        ]
        
        var messages: [[String: Any]] = [
            [
                "role": "developer",
                "content": systemPrompt
            ]
        ]
        
        AppProvider.shared.chatHistoryList.forEach { chatHistory in
            messages.append([
                "role": "user",
                "content": chatHistory.sendText
            ])
            messages.append([
                "role": "developer",
                "content": chatHistory.responseText ?? ""
            ])
        }
        
        var userMessageContent: [[String: Any]] = [
            ["type": "text", "text": message],
        ]
        
        imagesList.forEach { image in
            userMessageContent.append(
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(image)"]]
            )
        }
        
        messages.append([
            "role": "user",
            "content": userMessageContent,
        ])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 1024,
            "messages": messages,
            "stop": [
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream": true,
        ]
        
        var request = URLRequest(url: url)
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpMethod = "POST"
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Error: Unable to serialize JSON")
            throw ApiAnalysisError.invalidData
        }
        request.httpBody = jsonData
        
        let (result, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiAnalysisError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw ApiAnalysisError.invalidResponse
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await line in result.lines {
                        if line.hasPrefix("data: "), let data = line.dropFirst(6).data(using: .utf8), let response = try? JSONDecoder().decode(CompletionResponse.self, from: data), let text = response.choices.first?.delta.content {
                            continuation.yield(cleanResponseText(text))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
