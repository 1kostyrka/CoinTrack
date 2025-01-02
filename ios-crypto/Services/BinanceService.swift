//
//  BinanceService.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 26.12.2024.
//

import Foundation

func fetchCandleData(completion: @escaping ([CandleModel]?) -> Void) {
    let urlString = "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h"
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else {
            print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
            return
        }

        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[Any]] {
                let candles = jsonArray.compactMap { item -> CandleModel? in
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
                completion(candles)
            } else {
                completion(nil)
            }
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
            completion(nil)
        }
    }
    task.resume()
}
