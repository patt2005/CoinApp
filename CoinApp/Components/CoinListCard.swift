//
//  CoinListCard.swift
//  CoinApp
//
//  Created by Petru Grigor on 30.11.2024.
//

import SwiftUI

struct CoinListCard: View {
    let coin: Coin
    
    @ObservedObject private var appProvider = AppProvider.instance
    
    @EnvironmentObject var userViewModel: UserViewModel
    
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
            if userViewModel.isUserSubscribed {
                appProvider.path.append(.coinDetail(coin: coin))
            } else {
                withAnimation {
                    appProvider.showPaywall = true
                }
            }
        }) {
            VStack {
                Divider()
                    .background(Color.gray.opacity(0.25))
                    .padding(.leading, 20)
                    .padding(.leading, 60)
                HStack {
                    AsyncImage(url: URL(string: coin.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(30)
                                .blur(radius: !userViewModel.isUserSubscribed ? 4 : 0)
                        } else if phase.error != nil {
                            Rectangle()
                                .frame(width: 60, height: 60)
                                .cornerRadius(30)
                                .foregroundColor(AppConstants.grayColor )
                        } else {
                            ProgressView()
                                .frame(width: 60, height: 60)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(coin.symbol)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .blur(radius: !userViewModel.isUserSubscribed ? 4 : 0)
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
                .padding(.horizontal, 10)
            }
        }
        .onAppear {
            impactFeedback.prepare()
        }
    }
}
