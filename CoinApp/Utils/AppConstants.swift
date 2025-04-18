//
//  AppConstants.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import Foundation
import SwiftUI

let purchaseController = RCPurchaseController()

class AppConstants {
    static let backgroundColor: Color = Color(hex: "#050506")
    static let grayColor: Color = Color(hex: "#FFFFFF").opacity(0.1)
    static var primaryColor: Color = Color(hex: "#FF6500")
    
    static let revenueCatApiKey = "appl_JvpFINDddbyqKGswPhgybKrZwgb"
    static var openAiApiKey: String = ""
    static let superWallApiKey = "pk_bcb43ffa68186798f9b0f326960269a1c9e41b2a404cda6d"
    
    static let appCode: String = "meme-ai"
    
    struct ApiResponse: Decodable {
        let OPEN_AI_API_KEY: String
    }
    
    static func getApiKey() async {
        let apiUrl = "https://pattt2005.pythonanywhere.com/meme-ai/"
        
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: apiUrl)!)
            let content = try JSONDecoder().decode(ApiResponse.self, from: data)
            
            AppConstants.openAiApiKey = content.OPEN_AI_API_KEY
        } catch {
            print("Caught an error retrieving API key: \(error.localizedDescription)")
        }
    }
}

enum AppDestination: Hashable {
    case coinDetail(coin: Coin)
    case chartAnalysis(image: UIImage?, analysis: MemeCoinAnalysisResponse?)
    case searchCoin
    case postDetails(post: Post)
    case newsDetails(id: String)
}

func buildFormattedPrice(_ price: Double) -> some View {
    if price < 1e-5 {
        let formattedPrice = String(format: "%.15f", price)
        let parts = formattedPrice.split(separator: ".")
        
        guard parts.count == 2 else {
            return AnyView(Text("$0.00000").foregroundStyle(.white))
        }

        let wholePart = String(parts[0])
        let decimalPart = String(parts[1])

        var zeroCount = 0
        var remainingDecimalPart = decimalPart

        for char in decimalPart {
            if char == "0" {
                zeroCount += 1
                remainingDecimalPart.removeFirst()
            } else {
                break
            }
        }

        let significantPart = remainingDecimalPart.prefix(4)

        return AnyView(
            HStack(spacing: 0) {
                Text("$\(wholePart).0")
                Text("\(zeroCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.top, 10)
                Text(significantPart)
            }
            .foregroundStyle(.white)
        )
    }

    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.minimumFractionDigits = 5
    numberFormatter.maximumFractionDigits = 15

    let formattedPrice = numberFormatter.string(from: NSNumber(value: price)) ?? "\(price)"

    return AnyView(Text("$\(formattedPrice.prefix(8))").foregroundStyle(.white))
}

func formatNumber(_ number: Double) -> String {
    func formatWithSuffix(_ value: Double, _ suffix: String) -> String {
        return value < 10 ? String(format: "%.2f%@", value, suffix) : String(format: "%.1f%@", value, suffix)
    }

    if number >= 1_000_000_000_000_000 {
        return formatWithSuffix(number / 1_000_000_000_000_000, "Q")
    } else if number >= 1_000_000_000_000 {
        return formatWithSuffix(number / 1_000_000_000_000, "T")
    } else if number >= 1_000_000_000 {
        return formatWithSuffix(number / 1_000_000_000, "B")
    } else if number >= 1_000_000 {
        let formatted = number / 1_000_000
        
        if abs(formatted - round(formatted)) < 0.001 {
            return String(format: "%.0fM", round(formatted))
        }
        return String(format: "%.2fM", formatted)
    } else if number >= 1_000 {
        return formatWithSuffix(number / 1_000, "K")
    } else {
        return String(format: "%.0f", number)
    }
}

func convertImageToBase64(image: UIImage) -> String? {
    guard let imageData = image.jpegData(compressionQuality: 1.0) else {
        return nil
    }
    return imageData.base64EncodedString()
}

func getFormattedDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM, yyyy"
    let formattedDate = dateFormatter.string(from: date)
    return formattedDate
}   

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
