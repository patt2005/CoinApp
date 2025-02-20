import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var selectedTab = 0
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $selectedTab
            .sink { newTab in
                self.impactFeedback.prepare()
                self.impactFeedback.impactOccurred()
            }
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    @ObservedObject private var appProvider = AppProvider.shared
    
    @State private var isSearchSheetPresented = false
    @State private var showAlert = false
    
    private var previewInfo: FeaturePreviewInfo = FeaturePreviewInfo(features: [
        Feature(text: "Track Meme Coins in Real-Time! 🚀📊", image: "image1"),
        Feature(text: "Get AI-Powered Chart Analysis 📈🤖", image: "image4"),
        Feature(text: "Explore Market Insights & Trends 🔥💡", image: "image2"),
        Feature(text: "Stay Updated with Trending News 📰⚡", image: "image3"),
    ])
    
    var body: some View {
        ZStack {
            NavigationStack(path: $appProvider.path) {
                TabView(selection: $viewModel.selectedTab) {
                    CoinListView()
                        .tabItem {
                            Label("Trending", systemImage: "waveform")
                        }
                        .tag(0)
                    
                    ChatView()
                        .tabItem {
                            Label("AI Chat", systemImage: "message.badge.waveform")
                        }
                        .tag(1)
                    
                    NewsListView()
                        .tabItem {
                            Label("News", systemImage: "doc.text.image")
                        }
                        .tag(2)
                    
                    AiToolsView()
                        .tabItem {
                            Label("AI Tools", systemImage: "wand.and.stars")
                        }
                        .tag(3)
                }
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.backgroundColor = UIColor(AppConstants.backgroundColor.opacity(0.7))
                    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppConstants.primaryColor)
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppConstants.primaryColor)]
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            appProvider.path.append(.searchCoin)
                        }) {
                            Image("search")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(AppConstants.primaryColor)
                        }
                    }
                }
                .navigationTitle("MemeAI")
                .navigationBarTitleDisplayMode(.inline)
                .background(AppConstants.backgroundColor)
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .coinDetail(let coin): CoinDetailsView(coin: coin)
                    case .chartAnalysis(let image, let analysis): ChartAnalysisView(image: image, analysis: analysis)
                    case .searchCoin: SearchView()
                    case .postDetails(let post): PostDetailsView(post: post)
                    case .newsDetails(let id): NewsDetailsView(id: id)
                    }
                }
                .blur(radius: appProvider.showOnboarding ? 4 : 0)
            }
            
            FeaturePreviewPopupView(isPresented: $appProvider.showPremiumFeature, previewInfo: previewInfo)
            
            if appProvider.showOnboarding {
                OnboardingView()
            }
        }
    }
}
