//
//  DetailView.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 24.12.2024.
//

import SwiftUI

struct DetailLoadingView: View {
    @Binding var coin: CoinModel?
    
    var body: some View {
        ZStack {
            if let coin = coin {
                DetailView(coin: coin)
            }
        }
    }
}

struct DetailView: View {
    @StateObject private var vm: DetailViewModel
    @State private var showNewGraphView = false
    
    init(coin: CoinModel) {
        _vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ChartView(coin: vm.coin)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .navigationTitle(vm.coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text(vm.coin.name)
                        .font(.headline)
                    Spacer()
                    CoinImageView(coin: vm.coin)
                        .frame(width: 32, height: 32)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Switch the graph", action: {
                    showNewGraphView.toggle()
                })
                .background(Color.theme.background)
                .foregroundColor(Color.theme.secondaryText)
                .font(.callout)
                .padding()
            }
        }
        .background(
            NavigationLink(destination: CandleChartView(coin: vm.coin), isActive: $showNewGraphView) {
                EmptyView()
            }
        )
    }
}

#Preview {
    NavigationView {
        DetailView(coin: DeveloperPreview.instance.coin)
    }
}



