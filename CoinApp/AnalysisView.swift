//
//  AnalysisView.swift
//  CoinApp
//
//  Created by Petru Grigor on 30.11.2024.
//

import SwiftUI
import Combine

class AnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var memeCoinAnalisys: MemeCoinAnalysisResponse?
    @Published var showAlert: Bool = false
    
    @ObservedObject var appProvider = AppProvider.instance
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $selectedImage.sink { newImage in
            guard let selectedImage = newImage else {
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = true
            }
            
            Task {
                do {
                    self.memeCoinAnalisys = try await CMCApi.instance.analyzeChartImage(image: selectedImage)
                    
                    DispatchQueue.main.async {
                        if self.memeCoinAnalisys != nil {
                            self.isLoading = false
                            self.appProvider.path.append(.chartAnalysis(image: self.selectedImage, analysis: self.memeCoinAnalisys!))
                        } else {
                            print("Meme coin analysis failed")
                        }
                    }
                } catch {
                    self.showAlert = true
                }
            }
        }
        .store(in: &cancellables)
    }
}

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    
    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var showActionSheet = false
    
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                Text("MemeAI")
                    .foregroundStyle(AppConstants.primaryColor)
                    .font(Font.custom("Gabarito", size: 36))
                    .padding(.bottom, 5)
                    .padding(.top, 75)
                
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title)
                        .foregroundStyle(Color(hex: "#FFD737"))
                    
                    Text("AI Chart Analysis")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#FFD737"))
                }
                
                Text("Understand any chart with the help of the AI Chart Analysis! Take a photo of the chart and get instant information and details.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.gray)
                    .padding(.top, 25)
                    .padding(.horizontal, 30)
                
                Button(action: {
                    if userViewModel.isUserSubscribed {
                        showActionSheet = true
                    } else {
                        withAnimation {
                            viewModel.appProvider.showPaywall = true
                        }
                    }
                }) {
                    HStack(spacing: 7) {
                        Image("chart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding(.bottom, 7)
                        
                        Text("Get Analysis")
                            .font(Font.custom("Inter", size: 17).weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 9)
                    .padding(.top, 9)
                    .padding(.horizontal, 90)
                    .background(AppConstants.primaryColor)
                    .cornerRadius(18)
                    .padding(.top, 90)
                }
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView("Analyzing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                }
                
                HStack {
                    Spacer()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text("There was an error analyzing the chart. Please try again.")
        })
        .background(AppConstants.backgroundColor)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Photo Options"),
                message: Text("Choose how you want to select a photo"),
                buttons: [
                    .default(Text("From Photos")) {
                        sourceType = .photoLibrary
                        isImagePickerPresented.toggle()
                    },
                    .default(Text("Take Picture")) {
                        sourceType = .camera
                        isImagePickerPresented.toggle()
                    },
                    .cancel {}
                ]
            )
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $viewModel.selectedImage, isImagePickerPresented: $isImagePickerPresented, sourceType: sourceType)
        }
    }
}

//#Preview {
//    AnalysisView()
//}
