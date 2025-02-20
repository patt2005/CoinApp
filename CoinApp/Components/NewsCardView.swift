//
//  NewsCardView.swift
//  CoinApp
//
//  Created by Petru Grigor on 14.02.2025.
//

import SwiftUI

struct NewsCardView: View {
    let info: NewsItem
    
    var sentimentColor: Color {
        switch info.sentiment.lowercased() {
        case "positive": return .green
        case "negative": return .red
        default: return .yellow
        }
    }
    
    func formattedPublishedDate() -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = dateFormatter.date(from: info.publishedDate) {
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium
            localFormatter.timeStyle = .short
            localFormatter.locale = Locale.current
            
            return localFormatter.string(from: date)
        }
        return "Unknown Date"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(info.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Text("\(formattedPublishedDate())")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(info.sentiment.capitalized)
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sentimentColor.opacity(0.2))
                .foregroundColor(sentimentColor)
                .cornerRadius(10)
            
            Text(info.content)
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
