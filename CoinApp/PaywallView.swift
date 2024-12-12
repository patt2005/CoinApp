//
//  PaywallView.swift
//  CoinApp
//
//  Created by Petru Grigor on 01.12.2024.
//

import SwiftUI
import RevenueCat
import AppTrackingTransparency

struct PaywallView: View {
    @State private var currentOffering: Offering?
    
    @ObservedObject private var appProvider = AppProvider.instance
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Button(action: {
                    Task {
                        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                            
                            _ = await ATTrackingManager.requestTrackingAuthorization()
                        }
                    }
                    appProvider.showPaywall = false
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                Spacer()
            }
            .padding(.top, 8)
            
            HStack(alignment: .center) {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundStyle(Color(hex: "#FFD737"))
                
                Text("MemeAI Pro Access")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(hex: "#FFD737"))
            }
            .padding(.top, 25)
            
            Text("Upgrade to Pro Subscription to Unlock All Features")
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .font(Font.custom("Inter", size: 24).weight(.medium))
                .foregroundColor(AppConstants.primaryColor)
                .padding(.top, 25)
            
            HStack {
                Text("3 Days Free Trial")
                    .font(Font.custom("Inter", size: 16).weight(.bold))
                    .foregroundStyle(.white)
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 7)
            .background(.gray.opacity(0.3))
            .cornerRadius(20)
            .padding(.vertical, 30)
            
            VStack(alignment: .trailing) {
                HStack {
                    Text("AI Chart Analysis")
                        .font(Font.custom("Inter", size: 17))
                        .foregroundStyle(.white)
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(.bottom, 10)
                HStack {
                    Text("Access to Private Community Chats")
                        .font(Font.custom("Inter", size: 17))
                        .foregroundStyle(.white)
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(.bottom, 10)
                HStack {
                    Text("Customizable Coin Alerts")
                        .font(Font.custom("Inter", size: 17))
                        .foregroundStyle(.white)
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(.bottom, 10)
                HStack {
                    Text("Remove Ads")
                        .font(Font.custom("Inter", size: 17))
                        .foregroundStyle(.white)
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .padding(.bottom, 10)
            }
            .padding(.trailing, 10)
            
            if let currentOffering = currentOffering {
                HStack {
                    Spacer()
                    Button(action: {
                        isPurchasing = true
                        Purchases.shared.purchase(package: currentOffering.availablePackages.first!) { (transaction, customerInfo, error, userCancelled) in
                            if customerInfo?.entitlements.all["pro"]?.isActive == true {
                                withAnimation {
                                    userViewModel.isUserSubscribed = true
                                    appProvider.showPaywall = false
                                }
                            }
                            isPurchasing = false
                        }
                    }) {
                        ZStack {
                            if isPurchasing {
                                ProgressView()
                            }
                            Text("Try Free & Subscribe")
                                .font(Font.custom("Inter", size: 21)).fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .opacity(isPurchasing ? 0 : 1)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 13)
                        .background(AppConstants.primaryColor)
                        .cornerRadius(30)
                    }
                    Spacer()
                }
                .padding(.top, 80)
                
                HStack {
                    Spacer()
                    VStack {
                        Text("Try 3 days free, then \(currentOffering.availablePackages.first!.localizedPriceString) / week.")
                            .font(Font.custom("Inter", size: 16))
                            .foregroundStyle(.gray)
                        
                        Text("Cancel anytime.")
                            .font(Font.custom("Inter", size: 16))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            
            Spacer()
            
            HStack {
                Link(destination: URL(string: "https://docs.google.com/document/d/1uth_ytIH6sL8eJu1w2loQkPMonuRYz-c1yq5xkVK71k/edit?usp=sharing")!) {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Link(destination: URL(string: "https://docs.google.com/document/d/1VbemNFyZpawCaigbmEPzndAt3HN-iH4VsMH0Znsi-gU/edit?usp=sharing")!) {
                    Text("Terms of Use")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Button(action: {
                    Purchases.shared.restorePurchases { customerInfo, error in
                        userViewModel.isUserSubscribed = customerInfo?.entitlements.all["pro"]?.isActive == true
                    }
                }) {
                    Text("Restore Purchase")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
        .onAppear {
            Purchases.shared.getOfferings { offerings, error in
                if let offer = offerings?.current, error == nil {
                    currentOffering = offer
                }
            }
        }
        .padding(.horizontal, 20)
        .background(.black.opacity(0.8))
    }
}

#Preview {
    PaywallView()
}
