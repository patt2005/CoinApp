//
//  ChartAnalysisView.swift
//  CoinApp
//
//  Created by Petru Grigor on 28.11.2024.
//

import SwiftUI

struct ChartAnalysisView: View {
    var image: UIImage?
    var analysis: MemeCoinAnalysisResponse?
    
    var body: some View {
        if let analysis = analysis {
            ScrollView {
                VStack(alignment: .center) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(2.5)
                            .frame(height: 200)
                            .padding(.top, 15)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("General Trend")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.vertical, 10)
                        
                        Text(analysis.general_trend)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("Chart Pattern")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        Text(analysis.chart_pattern)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("Indicator Analysis")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        Text(analysis.indicator_analysis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("Future Market Prediction")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        Text(analysis.future_market_prediction)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                    }
                }
                .padding(.horizontal, 20)
                .preferredColorScheme(.dark)
                .background(AppConstants.backgroundColor)
            }
            .preferredColorScheme(.dark)
            .background(AppConstants.backgroundColor)
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
        } else {
            ProgressView()
                .frame(width: 35, height: 35)
            Text("Loading...")
                .preferredColorScheme(.dark)
        }
    }
}
