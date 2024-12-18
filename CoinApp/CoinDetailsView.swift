//
//  CoinDetailsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI

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
    
    @State private var priceData: [Double] = []
    @State private var selectedDateRange = "1d"
    @State private var showFullDescription = false
    
    private var dateRangeOptions: [String] = ["1h", "1d", "7d", "1m", "1y"]
    
    @State private var coinDetails: CoinDetails?
    @State private var trimValue: CGFloat = 0
    @State private var selectedPrice = 0.0
    @State private var memeCoinAnalysis: MemeCoinAnalysisResponse? = nil
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var isSharing = false
    
    @ObservedObject var appProvider = AppProvider.shared
    
    @State private var isCopied = false
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private func getAnalysis() async {
        isLoading = true
        
        do {
            let priceChangePercentage: Double
            switch selectedDateRange {
            case "1h":
                priceChangePercentage = coinDetails!.statistics.priceChangePercentage1h
            case "1d":
                priceChangePercentage = coinDetails!.statistics.priceChangePercentage24h
            case "7d":
                priceChangePercentage = coinDetails!.statistics.priceChangePercentage7d
            case "1m":
                priceChangePercentage = coinDetails!.statistics.priceChangePercentage30d
            case "1y":
                priceChangePercentage = coinDetails!.statistics.priceChangePercentage1y
            default:
                priceChangePercentage = 0
            }
            
            var marketCap: Double
            if let selfReportedMarketCap = coin.selfReportedMarketCap, selfReportedMarketCap != 0 {
                marketCap = selfReportedMarketCap
            } else {
                marketCap = coinDetails?.statistics.marketCap ?? 0.0
            }
            memeCoinAnalysis = try await OpenAiApi.shared.getCoinAnalysis(coin: coin, priceList: priceData, dateRange: selectedDateRange, marketCap: marketCap, priceChange: priceChangePercentage)
            
            DispatchQueue.main.async {
                if self.memeCoinAnalysis != nil {
                    self.appProvider.path.append(.chartAnalysis(image: nil, analysis: self.memeCoinAnalysis!))
                }
            }
        } catch {
            DispatchQueue.main.async {
                showAlert = true
            }
        }
        isLoading = false
    }
    
    private func loadData() async {
        priceData = await CMCApi.shared.getCoinPriceList(id: coin.id, dateRange: selectedDateRange)
        coinDetails = await CMCApi.shared.getCoinDetails(id: coin.id)
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
                priceData = await CMCApi.shared.getCoinPriceList(id: coin.id, dateRange: selectedDateRange)
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
        ZStack {
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
                                        .lineLimit(showFullDescription ? nil : 6)
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
                                                Text("\(formatNumber(coin.marketCap))")
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
                                
                                if let holderList = coinDetails.holders?.holderList {
                                    Text("Top holders")
                                        .font(Font.custom("Inter", size: 18).weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 10)
                                    
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
                                                            impactFeedback.impactOccurred()
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
                                    
                                    Text("Holders share")
                                        .font(Font.custom("Inter", size: 18).weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.top, 10)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            HolderRatioCard(title: "Top 10", ratio: coinDetails.holders!.topTenHolderRatio)
                                            HolderRatioCard(title: "Top 20", ratio: coinDetails.holders!.topTwentyHolderRatio)
                                            HolderRatioCard(title: "Top 50", ratio: coinDetails.holders!.topFiftyHolderRatio)
                                            HolderRatioCard(title: "Top 100 ", ratio: coinDetails.holders!.topHundredHolderRatio)
                                        }
                                        .padding(.top, 7)
                                    }
                                }
                                
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
                                        .padding(.top, 15)
                                        
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
                                                    impactFeedback.impactOccurred()
                                                    UIPasteboard.general.string = contractInfo.contractAddress
                                                    withAnimation {
                                                        isCopied = true
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        withAnimation {
                                                            isCopied = false
                                                        }
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "doc.on.doc")
                                                            .foregroundColor(.blue)
                                                        Text(isCopied ? "Copied" : "Copy")
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
                                            let link = "https://app.uniswap.org/swap?chain=\(chain)&outputCurrency=\(contractInfo.contractAddress)"
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
                                
                                Button(action: {
                                    Task {
                                        await getAnalysis()
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                        Text("Get analysis")
                                            .font(Font.custom("Inter", size: 18).weight(.medium))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(AppConstants.primaryColor)
                                    .cornerRadius(15)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                }
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
            .blur(radius: isLoading ? 4 : 0)
            .disabled(isLoading)
            .preferredColorScheme(.dark)
            .background(AppConstants.backgroundColor)
            .navigationTitle(coin.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .task {
                impactFeedback.prepare()
                await loadData()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Analysis Error"),
                    message: Text("Failed to analyze the meme coin. Please try again later."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            if isLoading {
                VStack {
                    ProgressView("Analyzing...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(activityItems: ["Check out \(coin.symbol) on Meme AI app: https://apps.apple.com/us/app/meme-ai-meme-coin-tracker-app/id6738891806"])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isSharing = true
                }) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(AppConstants.grayColor)
                            .frame(width: 35, height: 35)
                            .cornerRadius(17.5)
                        Image("share")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17.5, height: 17.5)
                    }
                }
            }
        }
    }
}
