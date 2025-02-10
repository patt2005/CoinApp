//
//  MessageRowView.swift
//  CoinApp
//
//  Created by Petru Grigor on 18.12.2024.
//

import SwiftUI

struct MessageRow: Identifiable, Equatable {
    let id = UUID()
    var isInteracting: Bool
    let sendText: String
    let responseImage: UIImage
    var responseText: String?
    var responseError: String?
    let uploadedImages: [UIImage]
    
    static func == (lhs: MessageRow, rhs: MessageRow) -> Bool {
        return lhs.id == rhs.id
    }
}

struct LoadingAnimation: View {
    @State private var showCircle1 = false
    @State private var showCircle2 = false
    @State private var showCircle3 = false
    
    private func performAnimation() {
        let animation = Animation.easeInOut(duration: 0.4)
        withAnimation(animation) {
            self.showCircle1 = true
            self.showCircle3 = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation (animation) {
                self.showCircle2 = true
                self.showCircle1 = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation (animation) {
                self.showCircle2 = false
                self.showCircle3 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.performAnimation()
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .opacity(showCircle1 ? 1 : 0)
            
            Circle()
                .opacity(showCircle2 ? 1 : 0)
            
            Circle()
                .opacity(showCircle3 ? 1 : 0)
        }
        .foregroundColor(.white)
        .onAppear(perform: performAnimation)
    }
}

struct MessageRowView: View {
    let messageRow: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    private func messageBubble(isUser: Bool, text: String, image: UIImage? = nil, responseError: String?, isLoading: Bool, imagesList: [UIImage] = []) -> some View {
        HStack(alignment: .top, spacing: 13) {
            if (!isUser) {
                Image(uiImage: image!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .cornerRadius(17.5)
            }
            
            VStack(alignment: isUser ? .trailing : .leading) {
                if !imagesList.isEmpty {
                    LazyVStack(alignment: .trailing, spacing: 10) {
                        ForEach(Array(imagesList.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                }
                
                if !text.isEmpty {
                    HStack(alignment: .top, spacing: 0) {
                        if isUser {
                            Spacer()
                        }
                        
                        Text(text)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                            .padding(isUser ? 12 : 0)
                            .background(isUser ? AppConstants.grayColor : AppConstants.backgroundColor)
                            .cornerRadius(isUser ? 16 : 0)
                    }
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button(action: {
                        retryCallback(messageRow)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                            
                            Text("Try again")
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                if isLoading {
                    LoadingAnimation()
                        .frame(width: 60, height: 30)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            messageBubble(isUser: true, text: messageRow.sendText, responseError: nil, isLoading: false, imagesList: messageRow.uploadedImages)
            
            if let message = messageRow.responseText {
                messageBubble(isUser: false, text: message, image: messageRow.responseImage, responseError: messageRow.responseError, isLoading: messageRow.isInteracting)
            }
        }
    }
}
