//
//  AiToolsView.swift
//  CoinApp
//
//  Created by Petru Grigor on 16.02.2025.
//

import SwiftUI

struct AiToolsView: View {
    struct ToolInfo {
        let title: String
        let image: String
        let description: String
        let url: URL
    }
    
    let tools: [ToolInfo] = [
        ToolInfo(
            title: "Qwently AI",
            image: "qwently",
            description: "Your personal AI companion for seamless conversations, deep insights, and instant assistance on any topic.",
            url: URL(string: "https://apps.apple.com/us/app/qwently-ai-chatbot-assistant/id6740526710")!
        ),
        ToolInfo(
            title: "Motivation AI",
            image: "motivation",
            description: "Daily AI-powered motivational quotes and affirmations tailored to uplift, inspire, and empower you every day.",
            url: URL(string: "https://apps.apple.com/us/app/motivation-stoic-daily-quotes/id6740817263")!
        ),
        ToolInfo(
            title: "Learn AI",
            image: "learn-ai",
            description: "A fun and interactive AI learning experience! Master coding, logic, and problem-solving with AI-driven lessons.",
            url: URL(string: "https://apps.apple.com/us/app/learnai-%C3%AEnva%C8%9B%C4%83-limba-rom%C3%A2n%C4%83/id6738118898")!
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                Text("AI Tools You Might Like")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                ForEach(tools, id: \.title) { tool in
                    ToolCardView(tool: tool)
                }
            }
            .padding(.vertical)
        }
        .background(AppConstants.backgroundColor)
        .navigationTitle("AI Tools")
    }
}

struct ToolCardView: View {
    let tool: AiToolsView.ToolInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                Image(tool.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(tool.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(tool.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            Link(destination: tool.url) {
                HStack {
                    Spacer()
                    Text("Download App")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.orange.opacity(0.4), radius: 4, x: 0, y: 2)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.2))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
