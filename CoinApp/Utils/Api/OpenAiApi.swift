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
                    You are a professional cryptocurrency analyst specializing in meme coins. 
                    Your expertise includes advanced technical analysis, trend identification, and market psychology. 
                    You analyze price movements, support and resistance levels, and leverage key indicators to determine market sentiment. 
                    You also consider external factors like social media trends, trading volume spikes, whale activity, and market liquidity. 
        
                    Your analysis must be objective, data-driven, and designed to help traders make informed decisions. 
                    Provide a structured breakdown of the coin's technicals, key levels, and potential market moves. 
        """
    
    private let jsonParams = """
                            Please return your analysis **strictly** in the following JSON format with **all fields included**:
                            
                            {
                                "general_trend": "A summary of the current trend (bullish, bearish, or neutral). Include trend strength, recent price movements, and key resistance/support levels.",
                                
                                "indicator_analysis": "A detailed breakdown of at least three indicators (e.g., RSI, MACD, Moving Averages, Bollinger Bands). Explain whether they confirm the trend or signal a reversal.",
                                
                                "chart_pattern": "Identify any recognizable chart patterns (e.g., triangles, head & shoulders, double tops/bottoms). Mention if they indicate a breakout, reversal, or trend continuation.",
                                
                                "future_market_prediction": "Provide a forecast based on technical and market conditions. Include potential price levels, risk factors, and scenarios for traders to watch."
                            }
                            
                            ⚠️ **Your response must always match this exact JSON structure.**
        """
    
    private let sampleJsonPrompt = """
                    {
                        "general_trend": "The meme coin is currently in a short-term uptrend, gaining 18% in the last 24 hours. Trading volume has increased by 120%, suggesting renewed interest. However, there is significant resistance at $0.0012, which has rejected price twice in the past week.",
                        
                        "indicator_analysis": "The RSI is at 68, approaching overbought conditions, indicating potential for a pullback. The 50-day moving average has crossed above the 200-day moving average (Golden Cross), historically signaling a bullish continuation. The MACD histogram is showing increasing bullish momentum, but traders should watch for potential divergence.",
                        
                        "chart_pattern": "A bullish pennant has formed on the 1-hour chart, suggesting a continuation pattern. If price breaks above $0.0012 with strong volume, a move toward $0.0015 is likely. However, failure to break out could lead to a retest of the $0.00085 support level.",
                        
                        "future_market_prediction": "If the coin sustains volume above $0.0012, the next resistance levels are $0.0015 and $0.0018. However, if momentum slows and RSI confirms a bearish divergence, a retracement to $0.0009 or lower could occur. Social sentiment remains positive, but traders should watch for sudden whale sell-offs or external news that could impact price movement."
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
