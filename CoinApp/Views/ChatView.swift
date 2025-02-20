//
//  ChatView.swift
//  CoinApp
//
//  Created by Petru Grigor on 17.12.2024.
//

import SwiftUI
import Combine
import SuperwallKit

class ChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isInteracting: Bool = false
    @Published var messages: [MessageRow] = []
    
    @Published var uploadedImages: [UIImage] = []
    @Published var selectedImage: UIImage?
    @Published var analysisImage: UIImage?
    
    @Published var isAnalazing: Bool = false
    
    @Published var showActionSheet: Bool = false
    @Published var showAnalysisSheet: Bool = false
    
    @Published var showAlert: Bool = false
    
    @ObservedObject var appProvider = AppProvider.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    @MainActor
    func sendTapped() async {
        let text = inputText
        inputText = ""
        await send(text)
    }
    
    init() {
        self.impactFeedback.prepare()
        
        $selectedImage.sink { newImage in
            guard let image = newImage else { return }
            
            self.uploadedImages.append(image)
        }
        .store(in: &cancellables)
        
        $analysisImage.sink { newImage in
            guard let image = newImage else { return }
            
            Task { @MainActor in
                self.isAnalazing = true
                let analysis = try? await OpenAiApi.shared.analyzeChartImage(image: image)
                
                if let analysis = analysis {
                    self.appProvider.path.append(.chartAnalysis(image: self.analysisImage, analysis: analysis))
                } else {
                    self.showAlert = true
                }
                
                self.isAnalazing = false
            }
        }
        .store(in: &cancellables)
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = self.messages.last?.id else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
    
    @MainActor
    func retry(messageRow: MessageRow) async {
        let index = messages.firstIndex { message in
            return messageRow.id == message.id
        }
        
        guard let index = index else { return }
        
        messages.remove(at: index)
        await send(messageRow.sendText)
    }
    
    @MainActor
    private func send(_ text: String) async {
        isInteracting = true
        var streamText = ""
        
        let imagesList = uploadedImages.map { image in
            return convertImageToBase64(image: image) ?? ""
        }
        var messageRow = MessageRow(isInteracting: true, sendText: text, responseImage: "small-icon", responseText: streamText, uploadedImages: self.uploadedImages)
        self.messages.append(messageRow)
        self.uploadedImages.removeAll()
        
        do {
            let stream = try await OpenAiApi.shared.getChatResponse(text, imagesList: imagesList)
            for try await text in stream {
                streamText += text
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        AppProvider.shared.chatHistoryList.append(messageRow)
        messageRow.isInteracting = false
        self.messages[self.messages.count - 1] = messageRow
        isInteracting = false
    }
}

struct ChatView: View {
    @StateObject var viewModel = ChatViewModel()
    @FocusState var isTextFieldFocused: Bool
    
    @State private var isImagePickerPresented: Bool = false
    @State private var isAnalysisImagePickerPresented: Bool = false
    
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack {
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 15) {
                                Image("icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(35)
                                
                                Text("Chat with your personal AI!")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .multilineTextAlignment(.center)
                                
                                Text("Understand any chart with the help of the AI Chart Analysis! Take a photo of the chart and get instant information and details.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, isTextFieldFocused ? 65 : 200)
                            .animation(.easeOut, value: isTextFieldFocused)
                        } else {
                            ForEach(viewModel.messages, id: \.id) { message in
                                MessageRowView(messageRow: message) { message in
                                    Task { @MainActor in
                                        await viewModel.retry(messageRow: message)
                                    }
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                    .sheet(isPresented: $isImagePickerPresented) {
                        ImagePicker(selectedImage: $viewModel.selectedImage, isImagePickerPresented: $isImagePickerPresented, sourceType: sourceType)
                    }
                    .sheet(isPresented: $isAnalysisImagePickerPresented) {
                        ImagePicker(selectedImage: $viewModel.analysisImage, isImagePickerPresented: $isAnalysisImagePickerPresented, sourceType: sourceType)
                    }
                    .actionSheet(isPresented: $viewModel.showAnalysisSheet) {
                        ActionSheet(
                            title: Text("Choose Photo Source"),
                            buttons: [
                                .default(Text("From Photos")) {
                                    sourceType = .photoLibrary
                                    isAnalysisImagePickerPresented = true
                                },
                                .default(Text("Take Photo")) {
                                    sourceType = .camera
                                    isAnalysisImagePickerPresented = true
                                },
                                .cancel {}
                            ]
                        )
                    }
                    .alert("Error", isPresented: $viewModel.showAlert, actions: {
                        Button("OK", role: .cancel) {}
                    }, message: {
                        Text("There was an error analyzing the chart. Please try again.")
                    })
                    
                    VStack {
                        if !viewModel.uploadedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 10) {
                                    ForEach(Array(viewModel.uploadedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(10)
                                                .clipped()
                                            
                                            Button(action: {
                                                viewModel.uploadedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: -5, y: 7)
                                        }
                                    }
                                }
                                .padding(.bottom, 10)
                                .padding(.top, 10)
                            }
                            .frame(height: 80)
                        }
                        
                        HStack {
                            Button(action: {
                                viewModel.impactFeedback.impactOccurred()
                                viewModel.showActionSheet = true
                            }) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27.5, height: 27.5)
                                    .foregroundColor(.white)
                            }
                            
                            TextField("Type here...", text: $viewModel.inputText)
                                .padding(.horizontal, 5)
                                .padding(.leading, 2)
                                .background(.clear)
                                .cornerRadius(15)
                                .foregroundColor(.white)
                                .focused($isTextFieldFocused)
                            
                            if viewModel.isInteracting {
                                LoadingAnimation()
                                    .frame(width: 40, height: 30)
                            } else {
                                Button(action: {
                                    if viewModel.inputText.isEmpty { return }
                                    Task { @MainActor in
                                        viewModel.impactFeedback.impactOccurred()
                                        isTextFieldFocused = false
                                        await viewModel.sendTapped()
                                        viewModel.scrollToBottom(proxy: proxy)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 31, height: 31)
                                        
                                        Image(systemName: "paperplane.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .fontWeight(.bold)
                                            .frame(width: 15.5, height: 15.5)
                                            .foregroundColor(.black.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        viewModel.scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.messages) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.scrollToBottom(proxy: proxy)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.gray.opacity(0.2))
                    .cornerRadius(20)
                    .padding(.horizontal, 13)
                    .padding(.bottom, 20)
                }
                .blur(radius: viewModel.isAnalazing ? 6: 0)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            viewModel.impactFeedback.impactOccurred()
                            if AppProvider.shared.isUserSubscribed {
                                viewModel.showAnalysisSheet = true
                            } else {
                                Superwall.shared.register(event: "campaign_trigger")
                            }
                        }) {
                            ZStack {
                                Rectangle()
                                    .frame(width: 47.5, height: 47.5)
                                    .cornerRadius(23.75)
                                    .foregroundStyle(AppConstants.primaryColor)
                                Image(systemName: "plus.viewfinder")
                                    .font(.title2.weight(.light))
                                    .foregroundColor(.white)
                            }
                        }
                        .actionSheet(isPresented: $viewModel.showActionSheet) {
                            ActionSheet(
                                title: Text("Choose Photo Source"),
                                buttons: [
                                    .default(Text("From Photos")) {
                                        sourceType = .photoLibrary
                                        isImagePickerPresented = true
                                    },
                                    .default(Text("Take Photo")) {
                                        sourceType = .camera
                                        isImagePickerPresented = true
                                    },
                                    .cancel {}
                                ]
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, 13)
                    .padding(.bottom, viewModel.uploadedImages.isEmpty ? 85 : 165)
                }
                .blur(radius: viewModel.isAnalazing ? 6: 0)
                
                if viewModel.isAnalazing {
                    Color.black.opacity(0.3)
                        .blur(radius: 6)
                        .ignoresSafeArea(edges: .all)
                    
                    VStack {
                        ProgressView("Analyzing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(AppConstants.backgroundColor)
    }
}
