//
//  AnalysisView.swift
//  CoinApp
//
//  Created by Petru Grigor on 30.11.2024.
//

import SwiftUI
import Combine
import SuperwallKit

class AnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var memeCoinAnalisys: MemeCoinAnalysisResponse?
    @Published var showAlert: Bool = false
    
    @ObservedObject var appProvider = AppProvider.shared
    
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
                self.memeCoinAnalisys = try? await OpenAiApi.shared.analyzeChartImage(image: selectedImage)
                
                DispatchQueue.main.async {
                    if self.memeCoinAnalisys != nil {
                        self.appProvider.path.append(.chartAnalysis(image: self.selectedImage, analysis: self.memeCoinAnalisys!))
                    } else {
                        self.showAlert = true
                    }
                    self.isLoading = false
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
    
    var body: some View {
        ScrollView {
            VStack {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(15)
                    .padding(.top, 50)
                
                Text("MemeAI")
                    .foregroundStyle(AppConstants.primaryColor)
                    .font(Font.custom("Gabarito", size: 36))
                    .padding(.bottom, 5)
                    .padding(.top, 25)
                
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
                    if AppProvider.shared.isUserSubscribed {
                        showActionSheet = true
                    } else {
                        Superwall.shared.register(event: "campaign_trigger")
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Analyze Chart")
                            .font(Font.custom("Inter", size: 17).weight(.bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 80)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding(.top, 60)
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
