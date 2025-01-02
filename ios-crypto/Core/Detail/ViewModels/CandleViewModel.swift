//
//  CandleViewModel.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 26.12.2024.
//

import Foundation
import Combine

class CandleViewModel: ObservableObject {
    @Published var candles: [CandleModel] = []
    @Published var isLoading = true
    private var webSocketTask: URLSessionWebSocketTask?
    private let symbol: String
    @Published var selectedHistory: History = .sevenDays
    private var timer: Timer?
    
    init(symbol: String) {
        self.symbol = symbol
    }
    
    func loadCandleData() {
        isLoading = true
        candles = []
        fetchHistoricalData()
        connectWebSocket()
    }
    
    enum History: String, CaseIterable {
        case fiveteenMin = "15m"
        case oneHour = "1h"
        case fourHours = "4h"
        case oneDay = "1d"
        case sevenDays = "7d"
    }
    
    private func getURL(for history: History) -> String {
        let baseURL = "https://api.binance.com/api/v3/klines?symbol=\(symbol)"
        let endTime = Int(Date().timeIntervalSince1970 * 1000)
        var startTime: Int
        var interval: String
        var limit: Int
        
        switch history {
        case .fiveteenMin:
            startTime = endTime - 15 * 60 * 1000
            interval = "1m"
            limit = 15
        case .oneHour:
            startTime = endTime - 60 * 60 * 1000
            interval = "1m"
            limit = 60
        case .fourHours:
            startTime = endTime - 4 * 60 * 60 * 1000
            interval = "5m"
            limit = 48
        case .oneDay:
            startTime = endTime - 24 * 60 * 60 * 1000
            interval = "15m"
            limit = 96
        case .sevenDays:
            startTime = endTime - 7 * 24 * 60 * 60 * 1000
            interval = "1h"
            limit = 168
        }
        
        return "\(baseURL)&interval=\(interval)&limit=\(limit)&startTime=\(startTime)&endTime=\(endTime)"
    }
    
    private func fetchHistoricalData() {
        let urlString = getURL(for: selectedHistory)
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching historical data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[Any]] {
                    let historicalCandles = jsonArray.compactMap { item -> CandleModel? in
                        guard
                            let time = item[0] as? TimeInterval,
                            let open = Double(item[1] as? String ?? ""),
                            let high = Double(item[2] as? String ?? ""),
                            let low = Double(item[3] as? String ?? ""),
                            let close = Double(item[4] as? String ?? "")
                        else { return nil }
                        
                        return CandleModel(
                            time: Date(timeIntervalSince1970: time / 1000),
                            open: open,
                            high: high,
                            low: low,
                            close: close
                        )
                    }
                    
                    DispatchQueue.main.async {
                        self?.candles = historicalCandles
                        self?.isLoading = false
                    }
                }
            } catch {
                print("Error parsing historical data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func connectWebSocket() {
        disconnectWebSocket()
        
        let interval: String
        switch selectedHistory {
        case .fiveteenMin:
            interval = "1m"
        case .oneHour:
            interval = "1m"
        case .fourHours:
            interval = "5m"
        case .oneDay:
            interval = "15m"
        case .sevenDays:
            interval = "1h"
        }
        
        guard let url = URL(string: "wss://stream.binance.com:9443/ws/\(symbol.lowercased())@kline_\(interval)") else {
            print("Invalid URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchHistoricalData()
        }
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        timer?.invalidate()
        timer = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let k = json["k"] as? [String: Any],
              let time = k["t"] as? TimeInterval,
              let open = Double(k["o"] as? String ?? ""),
              let high = Double(k["h"] as? String ?? ""),
              let low = Double(k["l"] as? String ?? ""),
              let close = Double(k["c"] as? String ?? "") else {
            return
        }
        
        DispatchQueue.main.async {
            let newCandle = CandleModel(
                time: Date(timeIntervalSince1970: time / 1000),
                open: open,
                high: high,
                low: low,
                close: close
            )
            
            if let lastCandle = self.candles.last, lastCandle.time == newCandle.time {
                self.candles[self.candles.count - 1] = newCandle
            } else {
                self.candles.append(newCandle)
                if self.candles.count > self.getLimitForCurrentInterval() {
                    self.candles.removeFirst()
                }
            }
        }
    }
    
    private func getLimitForCurrentInterval() -> Int {
        switch selectedHistory {
        case .fiveteenMin:
            return 15
        case .oneHour:
            return 60
        case .fourHours:
            return 48
        case .oneDay:
            return 96
        case .sevenDays:
            return 168
        }
    }
    
    deinit {
        disconnectWebSocket()
    }
}


