//
//  PostCard.swift
//  CoinApp
//
//  Created by Petru Grigor on 08.01.2025.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    
    private func formatTimestamp(_ timestamp: String) -> String {
        guard let rawTimeInterval = TimeInterval(timestamp) else {
            return "Invalid date"
        }
        
        let timeInterval = rawTimeInterval > 1_000_000_000_000 ? rawTimeInterval / 1000 : rawTimeInterval

        let date = Date(timeIntervalSince1970: timeInterval)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()
            
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.owner.avatar.url)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 40)
                }
                
                Text(post.owner.nickname)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }

            Text(post.textContent)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                Label(post.impressionCount, systemImage: "eye")
                Label(post.likeCount, systemImage: "hand.thumbsup")
                Label(post.repostCount, systemImage: "arrowshape.turn.up.right")
                
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            
            Text(formatTimestamp(post.postTime))
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            Spacer()
        }
        .padding()
        .background(AppConstants.grayColor)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
