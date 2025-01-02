//
//  CandleModel.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 26.12.2024.
//

import Foundation

 struct CandleModel: Identifiable {
    let id = UUID()
    let time: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}


