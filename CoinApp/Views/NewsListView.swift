//
//  NewsListView.swift
//  CoinApp
//
//  Created by Petru Grigor on 13.02.2025.
//

import SwiftUI
import SuperwallKit

struct NewsListView: View {
    @ObservedObject private var appProvider = AppProvider.shared
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            if appProvider.newsList.isEmpty {
                VStack {
                    ProgressView()
                        .frame(width: 35, height: 35)
                    Text("Loading...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.backgroundColor)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(appProvider.newsList) { news in
                            Button(action: {
                                impactFeedback.impactOccurred()
                                if appProvider.isUserSubscribed {
                                    appProvider.path.append(.newsDetails(id: news.id))
                                } else {
                                    Superwall.shared.register(event: "campaign_trigger")
                                }
                            }) {
                                NewsCardView(info: news)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                        }
                    }
                }
                .refreshable {
                    Task { @MainActor in
                        appProvider.newsList = await NewsApi.shared.fetchNews()
                    }
                }
                .background(AppConstants.backgroundColor)
            }
        }
        .onAppear {
            if appProvider.newsList.isEmpty {
                impactFeedback.prepare()
                Task { @MainActor in
                    appProvider.newsList = await NewsApi.shared.fetchNews()
                }
            }
        }
    }
}
