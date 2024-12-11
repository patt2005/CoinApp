//
//  ChartView.swift
//  CoinApp
//
//  Created by Petru Grigor on 30.11.2024.
//

import SwiftUI

struct Line:Shape{
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct PriceChart: View {
    let priceList: [Double]
    
    let minY: Double
    let maxY: Double
    let lineColor: Color
    
    @State private var offset: CGSize = .zero
    @State private var showPlot = false
    @State private var translation: CGFloat = 0
    
    @Binding private var trimValue: CGFloat
    @Binding private var selectedPrice: Double
    
    init(priceList: [Double], trimValue: Binding<CGFloat>, selectedPrice: Binding<Double>) {
        self.priceList = priceList
        let minPrice = priceList.min() ?? 0
        let maxPrice = priceList.max() ?? 0
        self.maxY = maxPrice
        self.minY = minPrice
        self.lineColor = ((priceList.last ?? 0) - (priceList.first ?? 0)) > 0 ? .green : .red
        self._trimValue = trimValue
        self._selectedPrice = selectedPrice
    }
    
    var body: some View {
        GeometryReader { geometry in
            if priceList.isEmpty {
                Text("No available data for this coin")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                let width = geometry.size.width / CGFloat(priceList.count - 1)
                let height = geometry.size.height
                
                let maxPoint = priceList.max() ?? 0
                let minPoint = priceList.min() ?? 0
                
                let points = priceList.enumerated().compactMap { item in
                    let progress = (item.element - minPoint) / (maxPoint - minPoint)
                    let pathHeight = progress * height
                    let pathWidth = width * CGFloat(item.offset)
                    
                    return CGPoint(x: pathWidth, y: -pathHeight + height)
                }
                
                Path { path in
                    for index in priceList.indices {
                        let xPosition = geometry.size.width / CGFloat(priceList.count) * CGFloat(index + 1)
                        let yAxis = maxY - minY
                        let yPosition = CGFloat((priceList[index] - minY) / yAxis) * geometry.size.height
                        
                        let invertedYPosition = geometry.size.height - yPosition
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: xPosition, y: invertedYPosition))
                        }
                        path.addLine(to: CGPoint(x: xPosition, y: invertedYPosition))
                    }
                }
                .trim(from: 0, to: trimValue)
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .onAppear {
                    withAnimation(.linear(duration: 1.5)) {
                        trimValue = 1
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(.black.opacity(0.01))
                .overlay {
                    ZStack {
                        Line()
                            .stroke(style: .init(dash: [5]))
                            .foregroundStyle(.gray)
                            .frame(width: 1)
                        
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(lineColor)
                            .offset(y: offset.height)
                    }
                    .offset(x: offset.width)
                    .opacity(showPlot ? 1 : 0)
                }
                .gesture(DragGesture().onChanged { value in
                    let translation = value.location.x
                    let index = max(min(Int((translation / width).rounded() + 1), priceList.count - 1), 0)
                    self.translation = translation
                    
                    withAnimation {
                        selectedPrice = priceList[index]
                        showPlot = true
                    }
                    
                    offset = CGSize(
                        width: points[index].x - (geometry.size.width / 2),
                        height: (points[index].y - height) + 75
                    )
                }.onEnded { value in
                    withAnimation {
                        showPlot = false
                    }
                })
            }
        }
    }
}
