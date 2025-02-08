//
//  PostDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 08.01.2025.
//

import SwiftUI

class PostDetailsViewModel: ObservableObject {
    @Published var selectedImageURL: String?
    @Published var isImageViewerPresented: Bool = false
}

struct PostDetailsView: View {
    let post: Post
    
    @StateObject private var viewModel = PostDetailsViewModel()
    
    init(post: Post) {
        self.post = post
    }
    
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
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                
                if let images = post.images {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(images, id: \.self) { image in
                                Button(action: {
                                    DispatchQueue.main.async {
                                        viewModel.selectedImageURL = image.url
                                        viewModel.isImageViewerPresented = true
                                    }
                                }) {
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
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: .infinity)
        }
        .background(AppConstants.backgroundColor)
        .fullScreenCover(isPresented: $viewModel.isImageViewerPresented) {
            ZStack {
                AppConstants.backgroundColor.edgesIgnoringSafeArea(.all)
                
                if let imageUrl = URL(string: viewModel.selectedImageURL ?? "https://www.statista.com/graphic/1/326707/bitcoin-price-index.jpg") {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.isImageViewerPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title3)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
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

