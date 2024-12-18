//
//  ChatView.swift
//  CoinApp
//
//  Created by Petru Grigor on 17.12.2024.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isInteracting: Bool = false
    @Published var messages: [MessageRow] = []
    
    @Published var uploadedImages: [UIImage] = []
    @Published var selectedImage: UIImage?
    
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func sendTapped() async {
        let text = inputText
        inputText = ""
        await send(text)
    }
    
    init() {
        $selectedImage.sink { newImage in
            if let image = newImage {
                self.uploadedImages.append(image)
            }
        }
        .store(in: &cancellables)
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
        var messageRow = MessageRow(isInteracting: true, sendText: text, sendImage: "userIcon", responseImage: "icon", responseText: streamText, uploadedImages: self.uploadedImages)
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
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var showActionSheet: Bool = false
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = viewModel.messages.last?.id else { return }
        
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                ScrollView {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "ellipsis.message.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.gray)
                            
                            Text("Message something to start the chat.")
                                .foregroundStyle(.secondary)
                                .font(.body)
                        }
                        .padding(.top, 250)
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
                            .padding(.horizontal, 14)
                        }
                        .frame(height: 80)
                    }
                    
                    HStack {
                        Button(action: {
                            showActionSheet = true
                        }) {
                            Image(systemName: "photo.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                        }
                        
                        TextField("Message", text: $viewModel.inputText)
                            .foregroundColor(.white)
                            .disableAutocorrection(true)
                            .focused($isTextFieldFocused)
                            .disabled(viewModel.isInteracting)
                        
                        if viewModel.isInteracting {
                            LoadingAnimation()
                                .frame(width: 40, height: 30)
                        } else {
                            Button(action: {
                                if viewModel.inputText.isEmpty { return }
                                Task { @MainActor in
                                    withAnimation {
                                        scrollToBottom(proxy: proxy)
                                    }
                                    isTextFieldFocused = false
                                    await viewModel.sendTapped()
                                }
                            }) {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(15)
                                    
                                    Image(systemName: "arrow.up")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.gray.opacity(0.2))
                .cornerRadius(20)
                .padding(.horizontal, 13)
                .padding(.bottom, 20)
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(selectedImage: $viewModel.selectedImage, isImagePickerPresented: $isImagePickerPresented, sourceType: sourceType)
                }
                .actionSheet(isPresented: $showActionSheet) {
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
            }
            
        }
        .background(AppConstants.backgroundColor)
    }
}
