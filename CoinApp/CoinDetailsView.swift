//
//  CoinDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI

struct CoinDetailsView: View {
    let coin: Coin
    
    @State private var priceData: [Double] = []
    @State private var selectedDateRange = "1d"
    @State private var showFullDescription = false
    
    private var dateRangeOptions: [String] = ["1h", "1d", "7d", "1m", "1y"]
    
    @State private var coinDetails: CoinDetails?
    @State private var trimValue: CGFloat = 0
    
    @State private var selectedPrice = 0.0
    
    private func loadData() async {
        priceData = await CMCApi.instance.getCoinPriceList(id: coin.id, dateRange: selectedDateRange)
        coinDetails = await CMCApi.instance.getCoinDetails(id: coin.id)
        selectedPrice = coinDetails?.statistics.price ?? 0
    }
    
    init(coin: Coin) {
        self.coin = coin
    }
    
    private func getDateRangeButton(index: Int) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            trimValue = 0
            selectedDateRange = dateRangeOptions[index]
            Task {
                priceData = await CMCApi.instance.getCoinPriceList(id: coin.id, dateRange: selectedDateRange)
                withAnimation(.linear(duration: 1.5)) {
                    trimValue = 1
                }
            }
        }) {
            Text(dateRangeOptions[index])
                .foregroundColor(selectedDateRange == dateRangeOptions[index] ? .white : .secondary)
                .frame(maxWidth: .infinity)
        }
    }
    
    var body: some View {
        VStack {
            if let coinDetails = coinDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            AsyncImage(url: URL(string: coin.imageUrl)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(30)
                                } else if phase.error != nil {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 60, height: 60)
                                } else {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                            }
                            VStack(alignment: .leading) {
                                HStack(spacing: 10) {
                                    Text(coinDetails.symbol)
                                        .font(.title.bold())
                                    buildFormattedPrice(selectedPrice)
                                }
                                coinDetails.getPriceChangeText(selectedDateRange)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        PriceChart(priceList: priceData.reversed(), trimValue: $trimValue, selectedPrice: $selectedPrice)
                            .frame(height: 150)
                        HStack {
                            ForEach(0..<dateRangeOptions.count, id: \.self) { i in
                                getDateRangeButton(index: i)
                            }
                        }
                        .padding(.top, 30)
                        VStack(alignment: .leading) {
                            Text("Details")
                                .foregroundStyle(.white)
                                .font(.title.bold())
                                .padding(.bottom, 5)
                            VStack(alignment: .leading) {
                                Text(coinDetails.description)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(showFullDescription ? nil : 3)
                                Button(showFullDescription ? "Show less" : "Read more") {
                                    withAnimation {
                                        showFullDescription = !showFullDescription
                                    }
                                }
                                .foregroundStyle(.white)
                            }
                            HStack {
                                VStack(spacing: 5) {
                                    HStack(spacing: 0) {
                                        Image(systemName: "number")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(coinDetails.statistics.rank)")
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                    Text("rank")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 15)
                                .background(AppConstants.grayColor)
                                .cornerRadius(15)
                                if coinDetails.statistics.marketCap != 0 {
                                    VStack(spacing: 5) {
                                        HStack(spacing: 0) {
                                            Image(systemName: "dollarsign.circle")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(formatNumber(coinDetails.statistics.marketCap))")
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                        }
                                        Text("market cap")
                                            .frame(maxWidth: .infinity)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 15)
                                    .background(AppConstants.grayColor)
                                    .cornerRadius(15)
                                }
                                VStack(spacing: 5) {
                                    HStack(spacing: 0) {
                                        Image(systemName: "chart.bar")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(formatNumber(coinDetails.volume))
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                    Text("volume")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 15)
                                .background(AppConstants.grayColor)
                                .cornerRadius(15)
                            }
                            .padding(.top, 10)
                            HStack {
                                VStack(spacing: 5) {
                                    HStack(spacing: 0) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(formatNumber(coinDetails.statistics.totalSupply))
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                    Text("total supply")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 15)
                                .background(AppConstants.grayColor)
                                .cornerRadius(15)
                                
                                VStack(spacing: 5) {
                                    HStack(spacing: 0) {
                                        Image(systemName: "calendar")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(getFormatedDate(date: coinDetails.dateAdded))
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                    Text("added date")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 15)
                                .background(AppConstants.grayColor)
                                .cornerRadius(15)
                            }
                            HStack {
                                if !coinDetails.urls.website.isEmpty {
                                    Link(destination: URL(string: coinDetails.urls.website.first!)!) {
                                        HStack {
                                            Image(systemName: "app.badge.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            Text("Website")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 15)
                                    .background(AppConstants.grayColor)
                                    .cornerRadius(15)
                                }
                                
                                if !coinDetails.urls.twitter.isEmpty {
                                    Link(destination: URL(string: coinDetails.urls.twitter.first!)!) {
                                        HStack {
                                            Image("twitter")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            Text("Twitter")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 15)
                                    .background(AppConstants.grayColor)
                                    .cornerRadius(15)
                                }
                            }
                            
//                            HStack {
//                                Image(systemName: "flame")
//                                    .font(.title2)
//                                Text("Get analysis")
//                                    .font(Font.custom("Inter", size: 18).weight(.medium))
//                                    .foregroundStyle(.white)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 15)
//                            .background(AppConstants.primaryColor)
//                            .cornerRadius(15)
//                            .padding(.top, 5)
//                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                    }
                }
            } else {
                VStack(alignment: .center) {
                    ProgressView()
                        .frame(width: 35, height: 35)
                    Text("Loading...")
                }
                .background(AppConstants.backgroundColor)
            }
        }
        .preferredColorScheme(.dark)
        .background(AppConstants.backgroundColor)
        .navigationTitle(coin.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .task {
            await loadData()
        }
    }
}
