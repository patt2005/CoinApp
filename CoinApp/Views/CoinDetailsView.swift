//
//  CoinDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI

class CoinDetailsViewModel: ObservableObject {
    @Published var priceData: [Double] = []
    @Published var coinDetails: CoinDetails?
    @Published var selectedPrice = 0.0
    
    @Published var selectedDateRange = "1d"
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var isSharing = false
    
    @Published var postsList: [Post] = []
    
    @Published var isCopied = false
    
    @Published var showFullDescription = false
    
    var dateRangeOptions: [String] = ["1h", "1d", "7d", "1m", "1y"]
    
    @Published var trimValue: CGFloat = 0
    @Published var memeCoinAnalysis: MemeCoinAnalysisResponse? = nil
    
    let coin: Coin
    
    init(coin: Coin) {
        self.coin = coin
        self.impactFeedback.prepare()
        Task { @MainActor in
            self.postsList = await CMCApi.shared.getTrendingPosts(id: self.coin.id)
            await loadData()
        }
    }
    
    func loadData() async {
        DispatchQueue.main.async {
            Task {
                self.priceData = await CMCApi.shared.getCoinPriceList(id: self.coin.id, dateRange: self.selectedDateRange)
                self.coinDetails = await CMCApi.shared.getCoinDetails(id: self.coin.id)
                self.selectedPrice = self.coinDetails?.statistics.price ?? 0
            }
        }
    }
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
}

struct CoinDetailsView: View {
    struct HolderRatioCard: View {
        let title: String
        let ratio: Double
        
        var body: some View {
            VStack(spacing: 10) {
                Text(title)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("\(ratio, specifier: "%.2f")%")
                    .font(.body.bold())
                    .foregroundColor(.green)
            }
            .padding()
            .frame(width: 150)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
        }
    }
    
    let coin: Coin
    
    @StateObject private var viewModel: CoinDetailsViewModel
    
    @ObservedObject var appProvider = AppProvider.shared
    
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    @State private var alertText = ""
    
    init(coin: Coin) {
        self.coin = coin
        _viewModel = StateObject(wrappedValue: CoinDetailsViewModel(coin: coin))
    }
    
    private func getAnalysis() async {
        viewModel.isLoading = true
        
        do {
            let priceChangePercentage: Double
            switch viewModel.selectedDateRange {
            case "1h":
                priceChangePercentage = viewModel.coinDetails!.statistics.priceChangePercentage1h
            case "1d":
                priceChangePercentage = viewModel.coinDetails!.statistics.priceChangePercentage24h
            case "7d":
                priceChangePercentage = viewModel.coinDetails!.statistics.priceChangePercentage7d
            case "1m":
                priceChangePercentage = viewModel.coinDetails!.statistics.priceChangePercentage30d
            case "1y":
                priceChangePercentage = viewModel.coinDetails!.statistics.priceChangePercentage1y
            default:
                priceChangePercentage = 0
            }
            
            var marketCap: Double
            if let selfReportedMarketCap = coin.selfReportedMarketCap, selfReportedMarketCap != 0 {
                marketCap = selfReportedMarketCap
            } else {
                marketCap = viewModel.coinDetails?.statistics.fullyDilutedMarketCap ?? 0.0
            }
            viewModel.memeCoinAnalysis = try await OpenAiApi.shared.getCoinAnalysis(coin: coin, priceList: viewModel.priceData, dateRange: viewModel.selectedDateRange, marketCap: marketCap, priceChange: priceChangePercentage)
            
            DispatchQueue.main.async {
                if let analysis = viewModel.memeCoinAnalysis {
                    appProvider.path.append(.chartAnalysis(image: nil, analysis: analysis))
                }
            }
        } catch {
            DispatchQueue.main.async {
                viewModel.showAlert = true
            }
        }
        viewModel.isLoading = false
    }
    
    private func getDateRangeButton(index: Int) -> some View {
        Button(action: {
            viewModel.impactFeedback.impactOccurred()
            viewModel.trimValue = 0
            viewModel.selectedDateRange = viewModel.dateRangeOptions[index]
            Task {
                viewModel.priceData = await CMCApi.shared.getCoinPriceList(id: coin.id, dateRange: viewModel.selectedDateRange)
                withAnimation(.linear(duration: 1.5)) {
                    viewModel.trimValue = 1
                }
            }
        }) {
            Text(viewModel.dateRangeOptions[index])
                .foregroundColor(viewModel.selectedDateRange == viewModel.dateRangeOptions[index] ? .white : .secondary)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func handleWatchlist() {
        Task {
            do {
                if appProvider.coinWatchList.contains(coin) {
                    try await UserApi.shared.removeFromWatchlist(coinId: coin.id)
                    appProvider.removeFromWatchlist(coin)
                    alertText = "The coin was successfully removed from the watchlist."
                } else {
                    try await UserApi.shared.addToWatchlist(coinId: coin.id)
                    appProvider.addToWatchlist(coin)
                    alertText = "The coin was successfully added to the watchlist."
                }
                showSuccessAlert = true
            } catch {
                showErrorAlert = true
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                if let coinDetails = viewModel.coinDetails {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
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
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 10) {
                                        Text(coinDetails.symbol)
                                            .font(.title.bold())
                                        buildFormattedPrice(viewModel.selectedPrice)
                                    }
                                    coinDetails.getPriceChangeText(viewModel.selectedDateRange)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 20)
                            
                            PriceChart(priceList: viewModel.priceData.reversed(), trimValue: $viewModel.trimValue, selectedPrice: $viewModel.selectedPrice)
                                .frame(height: 150)
                            
                            HStack {
                                ForEach(0..<viewModel.dateRangeOptions.count, id: \.self) { i in
                                    getDateRangeButton(index: i)
                                }
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 13)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Details")
                                    .foregroundStyle(.white)
                                    .font(.title.bold())
                                    .padding(.bottom, 5)
                                
                                VStack(alignment: .leading) {
                                    Text(coinDetails.description)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(viewModel.showFullDescription ? nil : 6)
                                    Button(viewModel.showFullDescription ? "Show less" : "Read more") {
                                        withAnimation {
                                            viewModel.showFullDescription = !viewModel.showFullDescription
                                        }
                                    }
                                    .foregroundStyle(.white)
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        viewModel.impactFeedback.impactOccurred()
                                        viewModel.isSharing = true
                                    }) {
                                        HStack {
                                            Image("share")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                            
                                            Text("Share")
                                                .font(Font.custom("Inter", size: 16).weight(.medium))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            await getAnalysis()
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("Get Analysis")
                                                .font(Font.custom("Inter", size: 16).weight(.medium))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(AppConstants.primaryColor)
                                        .cornerRadius(15)
                                    }
                                }
                                .padding(.top, 9)
                                
                                Text("Statistics")
                                    .foregroundStyle(.white)
                                    .font(.title.bold())
                                    .padding(.top, 13)
                                    .padding(.bottom, 7)
                                
                                VStack {
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
                                        
                                        VStack(spacing: 5) {
                                            HStack(spacing: 0) {
                                                Image(systemName: "dollarsign.circle")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                if let selfReportedMarketCap = coin.selfReportedMarketCap, selfReportedMarketCap != 0 {
                                                    Text("\(formatNumber(selfReportedMarketCap))")
                                                        .font(.headline.bold())
                                                        .foregroundStyle(.white)
                                                } else {
                                                    Text("\(formatNumber(coin.marketCap ?? 0.0))")
                                                        .font(.headline.bold())
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            Text("market cap")
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 15)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                        
                                        VStack(spacing: 5) {
                                            HStack(spacing: 0) {
                                                Image(systemName: "chart.bar")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text("$\(formatNumber(coinDetails.volume))")
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
                                                Text(getFormattedDate(date: coinDetails.dateAdded))
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
                                        VStack(spacing: 5) {
                                            HStack(spacing: 0) {
                                                Image(systemName: "star.fill")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text(formatNumber(Double(coinDetails.watchCount) ?? 0.0))
                                                    .font(.headline.bold())
                                                    .foregroundStyle(.white)
                                            }
                                            Text("watch count")
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 15)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                        
                                        VStack(spacing: 5) {
                                            HStack(spacing: 0) {
                                                Image(systemName: "waveform.path.ecg")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text("\(coinDetails.statistics.volumeRank)")
                                                    .font(.headline.bold())
                                                    .foregroundStyle(.white)
                                            }
                                            Text("volume rank")
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 15)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                    }
                                    
                                    HStack {
                                        VStack(spacing: 3) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "arrow.up.right.circle.fill")
                                                    .font(.headline)
                                                    .foregroundColor(.green)
                                                buildFormattedPrice(coinDetails.statistics.highAllTime)
                                            }
                                            Text("all-time high")
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                        
                                        VStack(spacing: 3) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "arrow.down.right.circle.fill")
                                                    .font(.headline)
                                                    .foregroundColor(.red)
                                                buildFormattedPrice(coinDetails.statistics.lowAllTime)
                                            }
                                            Text("all-time low")
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(AppConstants.grayColor)
                                        .cornerRadius(15)
                                    }
                                    .frame(height: 75)
                                    
                                    HStack {
                                        if !coinDetails.urls.website.isEmpty {
                                            Link(destination: URL(string: coinDetails.urls.website.first!)!) {
                                                HStack {
                                                    Image(systemName: "globe")
                                                        .font(.title2)
                                                        .foregroundColor(.blue)
                                                    Text("Website")
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .foregroundColor(.blue)
                                            }
                                            .padding(.vertical, 21.5)
                                            .background(AppConstants.grayColor)
                                            .cornerRadius(15)
                                        }
                                        
                                        if !coinDetails.urls.twitter.isEmpty {
                                            Link(destination: URL(string: coinDetails.urls.twitter.first!)!) {
                                                HStack {
                                                    Image("twitter")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 28, height: 28)
                                                        .cornerRadius(14)
                                                    Text("Twitter")
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .foregroundColor(.blue)
                                            }
                                            .padding(.vertical, 21.5)
                                            .background(AppConstants.grayColor)
                                            .cornerRadius(15)
                                        }
                                    }
                                }
                                
                                if let holderList = coinDetails.holders?.holderList {
                                    Text("Top holders")
                                        .font(Font.custom("Inter", size: 18).weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 10)
                                        .padding(.top, 8)
                                    
                                    VStack(spacing: 15) {
                                        ForEach(holderList.prefix(5), id: \.address) { holder in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Address")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    HStack {
                                                        Text(holder.address)
                                                            .font(.body)
                                                            .lineLimit(1)
                                                            .truncationMode(.middle)
                                                            .foregroundColor(.white)
                                                        
                                                        Button(action: {
                                                            viewModel.impactFeedback.impactOccurred()
                                                            UIPasteboard.general.string = holder.address
                                                        }) {
                                                            Image(systemName: "doc.on.doc")
                                                                .foregroundColor(.blue)
                                                        }
                                                        .buttonStyle(BorderlessButtonStyle())
                                                    }
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing) {
                                                    Text("Balance")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Text("\(formatNumber(holder.balance))")
                                                        .font(.body.bold())
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            
                            if let holdersInfo = coinDetails.holders {
                                Text("Holders share")
                                    .font(Font.custom("Inter", size: 18).weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.top, 10)
                                    .padding(.leading, 10)
                                    .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 13) {
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .frame(width: 0)
                                        HolderRatioCard(title: "Top 10", ratio: holdersInfo.topTenHolderRatio)
                                        HolderRatioCard(title: "Top 20", ratio: holdersInfo.topTwentyHolderRatio)
                                        HolderRatioCard(title: "Top 50", ratio: holdersInfo.topFiftyHolderRatio)
                                        HolderRatioCard(title: "Top 100 ", ratio: holdersInfo.topHundredHolderRatio)
                                    }
                                    .padding(.top, 7)
                                }
                            }
                            
                            if !viewModel.postsList.isEmpty {
                                Text("Trending posts")
                                    .font(Font.custom("Inter", size: 18).weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.top, 16)
                                    .padding(.horizontal, 13)
                                    .padding(.bottom, 7)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 13) {
                                        ForEach(viewModel.postsList, id: \.postTime) { post in
                                            Button(action: {
                                                viewModel.impactFeedback.impactOccurred()
                                                appProvider.path.append(.postDetails(post: post))
                                            }) {
                                                PostCard(post: post)
                                                    .frame(width: 280, height: 160)
                                                    .cornerRadius(15)
                                            }
                                        }
                                    }
                                    .padding(.leading, 10)
                                }
                                .frame(height: 161)
                            }
                            
                            VStack {
                                if let contractInfo = coinDetails.platforms?.first {
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            AsyncImage(url: URL(string: contractInfo.imageUrl)) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 40, height: 40)
                                                        .clipShape(Circle())
                                                        .shadow(radius: 5)
                                                } else if phase.error != nil {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .foregroundColor(.red)
                                                        .frame(width: 40, height: 40)
                                                } else {
                                                    ProgressView()
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                            VStack(alignment: .leading) {
                                                Text(contractInfo.contractPlatform)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text("Contract Network")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.top, 16)
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Address")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text(contractInfo.contractAddress)
                                                    .font(.body)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Button(action: {
                                                    viewModel.impactFeedback.impactOccurred()
                                                    UIPasteboard.general.string = contractInfo.contractAddress
                                                    withAnimation {
                                                        viewModel.isCopied = true
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        withAnimation {
                                                            viewModel.isCopied = false
                                                        }
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "doc.on.doc")
                                                            .foregroundColor(.blue)
                                                        Text(viewModel.isCopied ? "Copied" : "Copy")
                                                            .font(.body)
                                                            .foregroundStyle(.blue)
                                                    }
                                                    .padding(.trailing, 10)
                                                }
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                        }
                                        
                                        Button(action: {
                                            if let url = URL(string: "https://phantom.app/ul/buy?tokenAddress=\(contractInfo.contractAddress)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            HStack {
                                                Image("phantom")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 28, height: 28)
                                                
                                                Text("Trade on Phantom")
                                                    .font(Font.custom("Inter", size: 18).weight(.medium))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 15)
                                            .background(Color.purple)
                                            .cornerRadius(15)
                                            .padding(.top, 8)
                                        }
                                        
                                        Button(action: {
                                            var chain = ""
                                            switch contractInfo.contractPlatform {
                                            case "Base":
                                                chain = "base"
                                                break
                                            case "Ethereum":
                                                chain = "mainnet"
                                                break
                                            case "BNB Smart Chain (BEP20)":
                                                chain = "bnb"
                                                break
                                            default:
                                                break
                                            }
                                            
                                            var link = "https://app.uniswap.org/swap?chain=\(chain)&outputCurrency=\(contractInfo.contractAddress)"
                                            if chain.isEmpty {
                                                link = "https://app.uniswap.org/swap?outputCurrency=\(contractInfo.contractAddress)"
                                            }
                                            if let url = URL(string: link) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            HStack {
                                                Image("uniswap")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 28, height: 28)
                                                
                                                Text("Trade on Uniswap")
                                                    .font(Font.custom("Inter", size: 18).weight(.medium))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 15)
                                            .background(.pink)
                                            .cornerRadius(15)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable {
                        Task {
                            await viewModel.loadData()
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
            .blur(radius: viewModel.isLoading ? 4 : 0)
            .disabled(viewModel.isLoading)
            .preferredColorScheme(.dark)
            .background(AppConstants.backgroundColor)
            .navigationTitle(coin.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Analysis Error"),
                    message: Text("Failed to analyze the meme coin. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Success", isPresented: $showSuccessAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(alertText)
            })
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text("There was an error adding the coin to the watchlist. Please try again.")
            })
            
            if viewModel.isLoading {
                VStack {
                    ProgressView("Analyzing...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $viewModel.isSharing) {
            ActivityView(activityItems: ["Check out \(coin.symbol) on Meme AI app: https://apps.apple.com/us/app/meme-ai-meme-coin-tracker-app/id6738891806"])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.impactFeedback.impactOccurred()
                    handleWatchlist()
                }) {
                    if appProvider.coinWatchList.contains(coin) {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 23, height: 23)
                            .foregroundStyle(.yellow)
                    } else {
                        Image(systemName: "star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 23, height: 23)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}
