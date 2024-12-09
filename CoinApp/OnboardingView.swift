//
//  OnboardingView.swift
//  CoinApp
//
//  Created by Petru Grigor on 01.12.2024.
//

import SwiftUI
import StoreKit

struct OnboardingStep {
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    private let onboardingSteps: [OnboardingStep] = [
        .init(image: "onboarding1", title: "Welcome to MemeAI!", description: "Discover the world of meme coins with MemeAI! Whether you’re a crypto enthusiast or new to the market, MemeAI helps you identify meme coins and understand their behavior in the market."),
        OnboardingStep(image: "onboarding2", title: "Analyze Meme Coins with Ease", description: "With MemeAI, analyzing meme coins is simple and effective. Just upload an image of the chart, or snap a picture of it using your phone—it’s that easy!"),
        OnboardingStep(image: "onboarding3", title: "Stay Informed and Make Smarter Decissions", description: "Our real-time analysis keeps you updated with market movements, helping you make informed decisions."),
        OnboardingStep(image: "help", title: "Help Us Improve! Give Us a Quick Review", description: "Your feedback is valuable to us! Please take a moment to rate your experience with our app.")
    ]
    
    @Environment(\.requestReview) var requestReview
    
    @ObservedObject private var appProvider = AppProvider.instance
    
    @State private var currentStep: Int = 0
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            currentStep = onboardingSteps.count - 1
                        }
                    }) {
                        Text("Skip")
                            .padding(16)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .onAppear {
                impactFeedback.prepare()
            }
            
            TabView(selection: $currentStep) {
                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                    VStack {
                        Image(onboardingSteps[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                        
                        Text(onboardingSteps[index].title)
                            .font(Font.custom("Inter", size: 23)).bold()
                            .foregroundColor(AppConstants.primaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.vertical)
                        
                        Text(onboardingSteps[index].description)
                            .font(Font.custom("Inter", size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 30)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            HStack {
                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                    if index == currentStep {
                        Rectangle()
                            .frame(width: 60, height: 10)
                            .cornerRadius(10)
                            .foregroundStyle(AppConstants.primaryColor)
                    } else {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(Color(hex: "#2F2F30"))
                    }
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 80)
            
            Button(action: {
                impactFeedback.impactOccurred()
                if currentStep < onboardingSteps.count - 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else if currentStep == onboardingSteps.count - 2 {
                    withAnimation {
                        currentStep += 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        requestReview()
                    }
                } else {
                    withAnimation {
                        appProvider.completeOnboarding()
                        appProvider.showPaywall = true
                    }
                }
            }) {
                Text(currentStep == onboardingSteps.count - 1 ? "Get Started" : "Continue")
                    .font(Font.custom("Inter", size: 22).bold())
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#131517"))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
        .background(.black.opacity(0.8))
    }
}
