//
//  CandleChartView.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 26.12.2024.
//

import SwiftUI
import Charts

struct CandleChartView: View {
    @ObservedObject var vm: CandleViewModel
    
    @State private var dragLocation: CGPoint? = nil
    @State private var selectedCandle: CandleModel? = nil
    @State private var isDragging = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(coin: CoinModel) {
        self.vm = CandleViewModel(symbol: coin.symbol.uppercased() + "USDT")
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollProxy in
                        ZStack {
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Color.theme.accent)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            } else {
                                candleChart(in: geometry)
                                    .frame(width: calculateChartWidth(for: geometry))
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .gesture(
                                        SimultaneousGesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    if !isDragging {
                                                        isDragging = true
                                                    }
                                                    dragLocation = value.location
                                                    selectedCandle = getCandle(at: value.location, in: geometry)
                                                    offset = CGSize(
                                                        width: lastOffset.width + value.translation.width / scale,
                                                        height: 0
                                                    )
                                                }
                                                .onEnded { _ in
                                                    isDragging = false
                                                    lastOffset = offset
                                                },
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    let delta = value / lastScale
                                                    lastScale = value
                                                    scale *= delta
                                                    scale = min(max(scale, 1), 5)
                                                }
                                                .onEnded { _ in
                                                    lastScale = 1.0
                                                }
                                        )
                                    )
                                
                                if let dragLocation = dragLocation, let selectedCandle = selectedCandle {
                                    CrosshairView(location: dragLocation, candle: selectedCandle, geometry: geometry)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack {
                Button("15m") {
                    vm.selectedHistory = .fiveteenMin
                    vm.loadCandleData()
                }
                .buttonStyle(CustomButtonStyle())
                
                Button("1h") {
                    vm.selectedHistory = .oneHour
                    vm.loadCandleData()
                }
                .buttonStyle(CustomButtonStyle())
                
                Button("4h") {
                    vm.selectedHistory = .fourHours
                    vm.loadCandleData()
                }
                .buttonStyle(CustomButtonStyle())
                
                Button("1d") {
                    vm.selectedHistory = .oneDay
                    vm.loadCandleData()
                }
                .buttonStyle(CustomButtonStyle())
                
                Button("7d") {
                    vm.selectedHistory = .sevenDays
                    vm.loadCandleData()
                }
                .buttonStyle(CustomButtonStyle())
            }
            .background(Color.theme.accent)
            .cornerRadius(10)
            .frame(height: 100)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            vm.loadCandleData()
        }
    }
    
    private func calculateChartWidth(for geometry: GeometryProxy) -> CGFloat {
        let baseWidth = geometry.size.width * 2.5
        let scaledWidth = CGFloat(vm.candles.count) * candleWidth(for: scale) * 1.2
        
        return max(min(scaledWidth, geometry.size.width * 2.5), geometry.size.width)
    }
    
    private func candleWidth(for scale: CGFloat) -> CGFloat {
        return max(6.0, 12.0 * scale)
    }
    
    private func candleChart(in geometry: GeometryProxy) -> some View {
        Chart {
            ForEach(vm.candles) { candle in
                RectangleMark(
                    x: .value("Time", candle.time),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high),
                    width: .fixed(candleWidth(for: scale) / 3)
                )
                .foregroundStyle(.gray)
                
                RectangleMark(
                    x: .value("Time", candle.time),
                    yStart: .value("Open", candle.open),
                    yEnd: .value("Close", candle.close),
                    width: .fixed(candleWidth(for: scale))
                )
                .foregroundStyle(candle.open < candle.close ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: .hour, count: 4)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: priceDomain())
        .frame(height: geometry.size.height * 0.8)
    }
    
    private func priceDomain() -> ClosedRange<Double> {
        let visibleCandles = getVisibleCandles(vm.candles)
        let minPrice = visibleCandles.map { $0.low }.min() ?? 0
        let maxPrice = visibleCandles.map { $0.high }.max() ?? 100
        let padding = (maxPrice - minPrice) * 0.1
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    private func getVisibleCandles(_ candles: [CandleModel]) -> [CandleModel] {
        let startIndex = max(0, Int(-offset.width / (candleWidth(for: scale) * scale)))
        let visibleCount = Int(Double(candles.count) / scale)
        let endIndex = min(candles.count, startIndex + visibleCount)
        
        guard startIndex < endIndex else {
            return []
        }
        return Array(candles[startIndex..<endIndex])
    }
    
    private func getCandle(at location: CGPoint, in geometry: GeometryProxy) -> CandleModel? {
        let xScale = calculateChartWidth(for: geometry) / CGFloat(vm.candles.count)
        let index = Int((location.x - offset.width) / (xScale * scale))
        if index >= 0 && index < vm.candles.count {
            return vm.candles[index]
        }
        return nil
    }
}

struct CrosshairView: View {
    let location: CGPoint
    let candle: CandleModel
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: location.y))
                path.addLine(to: CGPoint(x: geometry.size.width, y: location.y))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundColor(.gray)
            
            Path { path in
                path.move(to: CGPoint(x: location.x, y: 0))
                path.addLine(to: CGPoint(x: location.x, y: geometry.size.height))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("O: \(candle.open, specifier: "%.2f")")
                Text("H: \(candle.high, specifier: "%.2f")")
                Text("L: \(candle.low, specifier: "%.2f")")
                Text("C: \(candle.close, specifier: "%.2f")")
            }
            .font(.caption)
            .padding(6)
            .background(Color(UIColor.systemBackground).opacity(0.9))
            .cornerRadius(5)
            .shadow(radius: 2)
            .position(x: geometry.size.width - 60, y: location.y)
            
            Text(candle.time, style: .date)
                .font(.caption)
                .padding(6)
                .background(Color(UIColor.systemBackground).opacity(0.9))
                .cornerRadius(5)
                .shadow(radius: 2)
                .position(x: location.x, y: geometry.size.height - 20)
        }
    }
}

#Preview {
    CandleChartView(coin: DeveloperPreview.instance.coin)
}









