//
//  NewsDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 14.02.2025.
//

import SwiftUI

class NewsDetailsViewModel: ObservableObject {
    @Published var articleURL: URL?
    @Published var showWebView: Bool = false
}

struct NewsDetailsView: View {
    let id: String

    @State private var details: NewsDetails?
    @StateObject private var viewModel = NewsDetailsViewModel()

    var sentimentColor: Color {
        switch details?.sentiment.lowercased() {
        case "positive": return .green
        case "negative": return .red
        default: return .yellow
        }
    }

    var body: some View {
        ZStack {
            AppConstants.backgroundColor.edgesIgnoringSafeArea(.all)

            if let details = details {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(details.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                            .padding(.top)

                        HStack {
                            Text(details.sentiment.capitalized)
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(sentimentColor.opacity(0.2))
                                .foregroundColor(sentimentColor)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)

                        if details.coin != "" && details.coin.lowercased() != "n/a" {
                            HStack {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .foregroundColor(.yellow)
                                Text(details.coin.uppercased())
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("📰 Full Story")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(details.content)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal)

                        if !details.cryptoMarketImpact.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📊 Market Impact")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(details.cryptoMarketImpact)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.bottom, 5)
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 50)
                    }
                }
                .background(AppConstants.backgroundColor)

                VStack {
                    Spacer()
                    if let url = URL(string: details.url) {
                        Button(action: {
                            viewModel.articleURL = url
                            viewModel.showWebView = true
                        }) {
                            Text("Read Full Article")
                                .font(.headline)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 15)
            } else {
                VStack {
                    ProgressView()
                        .padding(.bottom, 10)
                    Text("Fetching news details...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task { @MainActor in
                details = await NewsApi.shared.getNewsDetails(id: id)
            }
        }
        .navigationTitle("News")
        .sheet(isPresented: $viewModel.showWebView) {
            if let articleURL = viewModel.articleURL {
                    NavigationView {
                        VStack {
                            WebView(request: URLRequest(url: articleURL))
                                .edgesIgnoringSafeArea(.all)
                        }
                        .navigationBarTitle("Article", displayMode: .inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    viewModel.showWebView = false // Dismiss the sheet
                                }
                            }
                        }
                    }
                }
        }
    }
}
