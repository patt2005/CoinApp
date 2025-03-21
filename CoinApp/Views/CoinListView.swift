//
//  CoinListView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI
import Combine
import SuperwallKit

class CoinListViewModel: ObservableObject {
    @Published var pickedDateRange = "1h"
    @Published var pickedCoinListType = "Gainers"
    @Published var isLoading: Bool = false
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private var cancellables = Set<AnyCancellable>()
    
    private func fetchData() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        await CMCApi.shared.fetchCoinData(dateRange: self.pickedDateRange)
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    init() {
        impactFeedback.prepare()
        
        $pickedDateRange.sink { newDate in
            Task {
                await CMCApi.shared.fetchCoinData(dateRange: self.pickedDateRange)
            }
        }
        .store(in: &cancellables)
    }
}

struct CoinListView: View {
    @ObservedObject private var appProvider = AppProvider.shared
    
    @StateObject private var viewModel = CoinListViewModel()
    
    @State private var hasFetchedApi = false
    
    private var dateRangeList = ["1h", "24h", "7d", "30d"]
    private var coinListType = ["Watch List", "Gainers", "Losers", "Most Visited", "Recently Added"]
    
    private func getIcon(_ type: String) -> some View {
        switch type {
        case "Gainers": return Image(systemName: "chart.line.uptrend.xyaxis.circle").foregroundStyle(.green)
        case "Losers": return Image(systemName: "chart.line.downtrend.xyaxis.circle").foregroundStyle(.red)
        case "Recently Added": return Image(systemName: "clock").foregroundStyle(.orange)
        case "Most Visited": return Image(systemName: "crown.fill").foregroundStyle(.brown)
        case "Watch List": return Image(systemName: "star.fill").foregroundStyle(.yellow)
        default:
            return Image(systemName: "arrow.up.circle.fill").foregroundStyle(.blue)
        }
    }
    
    private func getCoinListTypeCard(_ type: String) -> some View {
        Button(action: {
            viewModel.impactFeedback.impactOccurred()
            viewModel.pickedCoinListType = type
        }) {
            HStack(spacing: 8) {
                getIcon(type)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                Text(type)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.pickedCoinListType == type ? .white : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(hex: "#131517").opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(viewModel.pickedCoinListType == type ? Color(hex: "#808080").opacity(0.5) : .clear, lineWidth: 1)
            )
            .padding(4)
        }
    }
    
    private func getList(_ type: String) -> [Coin] {
        switch type {
        case "Gainers":
            return appProvider.gainersList
        case "Losers":
            return appProvider.losersList
        case "Recently Added":
            return appProvider.recentlyAddedList
        case "Most Visited":
            return appProvider.mostVisitedList
        case "Watch List":
            return appProvider.coinWatchList.reversed()
        default:
            return []
        }
    }
    
    private func getCoinScrollCard(coin: Coin) -> some View {
        Button(action: {
            viewModel.impactFeedback.impactOccurred()
            if appProvider.isUserSubscribed {
                appProvider.path.append(.coinDetail(coin: coin))
            } else {
                withAnimation {
                    appProvider.showPremiumFeature = true
                }
            }
        }) {
            HStack {
                AsyncImage(url: URL(string: coin.imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .cornerRadius(20)
                    } else if phase.error != nil {
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .cornerRadius(20)
                            .foregroundColor(AppConstants.grayColor)
                    } else {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(coin.symbol)
                        .font(.headline)
                        .foregroundStyle(.white)
                    coin.getPriceChangeText("24h")
                }
            }
            .padding(.leading, 5)
        }
    }
    
    private func refreshList() async {
        await CMCApi.shared.fetchCoinData(dateRange: viewModel.pickedDateRange)
        await CMCApi.shared.fetchTrendingCoins(timeFrame: viewModel.pickedDateRange)
        await CMCApi.shared.fetchRecentlyAddedCoins()
        await CMCApi.shared.fetchMostVisitedCoin(dateRange: viewModel.pickedDateRange)
    }
    
    init() {
        let appearance = UINavigationBarAppearance()
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(.white),
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(.white),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        appearance.backgroundColor = UIColor(AppConstants.backgroundColor)
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(width: 35, height: 35)
                Text("Loading...")
            } else {
                ScrollView {
                    HStack {
                        Text("Trending 🔥")
                            .fontWeight(.bold)
                            .font(.title2)
                        
                        Spacer()
                        if !appProvider.isUserSubscribed {
                            Button(action: {
                                Superwall.shared.register(event: "campaign_trigger")
                            }) {
                                ZStack {
                                    Circle()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(Color(hex: "#933A00"))
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(Color(hex: "#ffcb42"))
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    
                    if appProvider.trendingList.isEmpty {
                        HStack {
                            ProgressView()
                        }
                        .frame(width: UIScreen.main.bounds.width)
                        .frame(height: 30)
                        .padding(.top)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .frame(width: 4)
                                ForEach(appProvider.trendingList, id: \.self) { item in
                                    getCoinScrollCard(coin: item)
                                        .padding(.trailing, 10)
                                }
                            }
                        }
                        .frame(height: 30)
                        .padding(.top)
                    }
                    
                    
                    HStack {
                        Text("Discover 🚀")
                            .fontWeight(.bold)
                            .font(.title2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(width: 4)
                            ForEach(coinListType, id: \.self) { type in
                                getCoinListTypeCard(type)
                            }
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(width: 4)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    if viewModel.pickedCoinListType == coinListType[2] || viewModel.pickedCoinListType == coinListType[1] {
                        HStack(alignment: .bottom, spacing: 0) {
                            Text("Time range: ")
                                .foregroundStyle(.gray)
                            Text("\(viewModel.pickedDateRange)")
                                .foregroundStyle(.white)
                            Spacer()
                            Menu {
                                ForEach(dateRangeList, id: \.self) { item in
                                    Button(action: {
                                        viewModel.pickedDateRange = item
                                        Task {
                                            await refreshList()
                                        }
                                    }) {
                                        HStack {
                                            Text(item)
                                            if item == viewModel.pickedDateRange {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image("filter")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, 8)
                    }
                    if viewModel.pickedCoinListType == "Watch List" && getList(viewModel.pickedCoinListType).isEmpty {
                        LazyVStack(spacing: 20) {
                            Image(systemName: "bookmark.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                            
                            Text("Your coin watch list is empty now!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVStack {
                            ForEach(getList(viewModel.pickedCoinListType), id: \.id) { coin in
                                CoinListCard(coin: coin, type: viewModel.pickedCoinListType, pickedDateRange: $viewModel.pickedDateRange, showPreview: $appProvider.showPremiumFeature)
                            }
                            Divider()
                                .background(Color.gray.opacity(0.25))
                                .padding(.leading, 71)
                        }
                    }
                }
                .refreshable {
                    await refreshList()
                }
            }
        }
        .task {
            if !hasFetchedApi {
                await refreshList()
                await appProvider.loadWatchList()
                hasFetchedApi = true
            }
        }
        .preferredColorScheme(.dark)
        .background(AppConstants.backgroundColor)
    }
}
