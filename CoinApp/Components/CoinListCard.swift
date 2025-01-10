//
//  CoinListCard.swift
//  CoinApp
//
//  Created by Petru Grigor on 30.11.2024.
//

import SwiftUI
import SuperwallKit

struct CoinListCard: View {
    let coin: Coin
    
    @ObservedObject private var appProvider = AppProvider.shared
    
    @Binding var pickedDateRange: String
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    let type: String
    
    init(coin: Coin, type: String, pickedDateRange: Binding<String>) {
        self.coin = coin
        self.type = type
        self._pickedDateRange = pickedDateRange
    }
    
    var body: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            if appProvider.isUserSubscribed {
                appProvider.path.append(.coinDetail(coin: coin))
            } else {
                Superwall.shared.register(event: "campaign_trigger")
            }
        }) {
            VStack {
                Divider()
                    .background(Color.gray.opacity(0.25))
                    .padding(.leading, 71)
                HStack {
                    AsyncImage(url: URL(string: coin.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .cornerRadius(25)
                        } else if phase.error != nil {
                            Rectangle()
                                .frame(width: 50, height: 50)
                                .cornerRadius(25)
                                .foregroundColor(AppConstants.grayColor )
                        } else {
                            ProgressView()
                                .frame(width: 50, height: 50)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(coin.symbol)
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 0) {
                            Text("$\(formatNumber(coin.volume24h))")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Text(" Vol (24h)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        buildFormattedPrice(coin.price)
                        coin.getPriceChangeText(type == "Gainers" || type == "Losers" ? pickedDateRange : "24h")
                    }
                }
                .padding(.horizontal, 13)
            }
        }
        .onAppear {
            impactFeedback.prepare()
        }
    }
}
