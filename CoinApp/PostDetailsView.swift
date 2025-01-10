//
//  PostDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 08.01.2025.
//

import SwiftUI

struct PostDetailsView: View {
    let post: Post
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: post.owner.avatar.url)) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 50, height: 50)
                    }
                    
                    Text(post.owner.nickname)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(post.textContent)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let images = post.images {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(images, id: \.self) { image in
                                AsyncImage(url: URL(string: image.url)) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 150, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 150, height: 150)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                HStack(spacing: 20) {
                    Label(post.impressionCount, systemImage: "eye")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Label(post.likeCount, systemImage: "hand.thumbsup")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Label(post.repostCount, systemImage: "arrowshape.turn.up.right")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Text("Posted on \(formatTimestamp(post.postTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.horizontal, 13)
            .navigationTitle("Post Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(maxWidth: .infinity)
        .background(AppConstants.backgroundColor)
    }
    
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
}

