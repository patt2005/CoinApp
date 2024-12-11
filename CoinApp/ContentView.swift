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
    
    @ObservedObject private var appProvider = AppProvider.instance
    
    @State private var isSearchSheetPresented = false
    @State private var showAlert = false
    
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        ZStack {
            NavigationStack(path: $appProvider.path) {
                TabView(selection: $viewModel.selectedTab) {
                    CoinListView()
                        .tabItem {
                            Label("Trending", systemImage: "waveform")
                        }
                        .tag(0)
                    
                    AnalysisView()
                        .tabItem {
                            Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)
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
                        NavigationLink(destination: SearchView()) {
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
                    }
                }
                .blur(radius: appProvider.showPaywall || appProvider.showOnboarding ? 4 : 0)
            }
            
            if appProvider.showOnboarding {
                OnboardingView()
            } else if appProvider.showPaywall {
                PaywallView()
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
