//
//  SettingsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 25.11.2024.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @State private var showDisclaimer: Bool = false
    
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        Form {
            Section(header: Text("Legal")) {
                Link(destination: URL(string: "https://docs.google.com/document/d/1uth_ytIH6sL8eJu1w2loQkPMonuRYz-c1yq5xkVK71k/edit?usp=sharing")!) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Privacy Policy")
                            .foregroundColor(.gray)
                    }
                }
                
                Link(destination: URL(string: "https://docs.google.com/document/d/1VbemNFyZpawCaigbmEPzndAt3HN-iH4VsMH0Znsi-gU/edit?usp=sharing")!) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Terms of Use")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showDisclaimer = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Disclaimer")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text("About Us")) {
                Link(destination: URL(string: "https://codbun.com/About")!) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title2)// Icon color
                        Text("About Us")
                            .foregroundColor(.gray) // Text color
                    }
                }
                
                Link(destination: URL(string: "https://codbun.com/Work")!) {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.white)
                            .font(.title2)// Icon color
                        Text("Our Apps")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text("Feedback")) {
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
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Contact Us")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    requestReview()
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Rate Us")
                            .foregroundColor(.gray)
                    }
                }
            }
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
