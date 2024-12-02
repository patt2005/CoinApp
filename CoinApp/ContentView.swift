import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var path: [UUID] = []
    
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
    
    @State private var isSearchSheetPresented = false
    @State private var showAlert = false
    @State private var showOnboarding = true
    @State private var showPaywall = false
    
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        ZStack {
            NavigationStack(path: $viewModel.path) {
                TabView(selection: $viewModel.selectedTab) {
                    CoinListView(showPaywall:  $showPaywall)
                        .tabItem {
                            Label("Trending", systemImage: "waveform")
                        }
                        .tag(0)
                    
                    AnalysisView(path: $viewModel.path, showPaywall: $showPaywall)
                        .tabItem {
                            Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)
                }
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.backgroundColor = UIColor(AppConstants.backgroundColor.opacity(0.7))
                    appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
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
            }
            .blur(radius: showPaywall || showOnboarding ? 4 : 0)
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding, showPaywall: $showPaywall)
            } else if showPaywall && !userViewModel.isUserSubscribed {
                PaywallView(showPaywall: $showPaywall)
            }
        }
    }
}

#Preview {
    ContentView()
}
