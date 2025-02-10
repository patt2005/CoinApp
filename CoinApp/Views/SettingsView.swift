//
//  SettingsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI
import StoreKit

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @State private var showDisclaimer: Bool = false
    
    @State private var isSharing = false
    
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            Form {
                Section(header: Text("Feedback")) {
                    Button(action: {
                        isSharing = true
                    }) {
                        HStack {
                            Image("share-2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22.5, height: 22.5)
                            Text("Share App")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 8.5)
                        }
                    }
                    
                    Button(action: {
                        let email = "mihai@codbun.com"
                        let subject = "Support Request"
                        let body = "Hi, I need help with..."
                        let mailtoURL = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                        
                        if let url = URL(string: mailtoURL) {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            } else {
                                print("Mail app is not available")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Contact us")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Button(action: {
                        requestReview()
                    }) {
                        HStack {
                            Image(systemName: "hand.thumbsup")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Rate us")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 5)
                        }
                    }
                }
                
                Section(header: Text("Legal")) {
                    Link(destination: URL(string: "https://codbun.com/chatai/privacypolicy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Privacy Policy")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Link(destination: URL(string: "https://codbun.com/chatai/termsofuse")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Terms of Use")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Button(action: {
                        showDisclaimer = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Disclaimer")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Section(header: Text("About Us")) {
                    Link(destination: URL(string: "https://www.linkedin.com/company/codbun")!) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.headline)
                            Text("Follow us")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Link(destination: URL(string: "https://codbun.com/About")!) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("About us")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Link(destination: URL(string: "https://codbun.com/Work")!) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(AppConstants.primaryColor)
                                .font(.title2)
                            Text("Our Apps")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(activityItems: [
                "https://apps.apple.com/us/app/meme-ai-meme-coin-tracker-app/id6738891806"])
        }
        .alert(isPresented: $showDisclaimer) {
            Alert(
                title: Text("Important Disclaimer"),
                message: Text("The information provided by our AI model is not financial advice. Always do your own research before investing in meme coins or any other cryptocurrencies."),
                dismissButton: .default(Text("Understood"))
            )
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
