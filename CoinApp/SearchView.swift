//
//  SearchView.swift
//  CoinApp
//
//  Created by Petru Grigor on 29.11.2024.
//

import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Coin] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func search() async {
        DispatchQueue.main.async {
            self.isLoading = true
            Task {
                self.results = await CMCApi.instance.getCoinFromSearchQuery(self.searchText)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadInitialResults() {
        if results.isEmpty {
            self.results = AppProvider.instance.gainersList.shuffled()
        }
    }
    
    init() {
        $searchText
            .sink { newText in
                if !newText.isEmpty {
                    Task {
                        await self.search()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        ScrollView {
            HStack {
                Image("search.white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray)
                
                TextField("Search...", text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .disableAutocorrection(true)
            }
            .padding(10)
            .background(.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 30)
            .padding(.bottom, 15)
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .frame(width: 35, height: 35)
                    Text("Loading...")
                }
            } else {
                ForEach(viewModel.results, id: \.self) { coin in
                    CoinListCard(coin: coin, pickedDateRange: .constant("24h"))
                }
            }
            
        }
        .onAppear {
            viewModel.loadInitialResults()
        }
        .preferredColorScheme(.dark)
        .background(AppConstants.backgroundColor)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
    }
}
