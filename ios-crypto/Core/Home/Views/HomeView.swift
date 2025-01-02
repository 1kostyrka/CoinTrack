//
//  HomeView.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 23.12.2024.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    
    @State private var selectCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack {
                Text("Live prices")
                    .fontWeight(.bold)
                    .font(.title)
                    .foregroundColor(Color.theme.accent)
                
                HStack {
                    Text("Coin")
                    Spacer()
                    Text("Price")
                        .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
                }
                
                .font(.caption)
                .foregroundColor(Color.theme.secondaryText)
                .padding(.horizontal)
                
                List {
                    ForEach(vm.allCoins) { coin in
                        CoinRowView(coin: coin)
                            .padding(.horizontal, -12)
                            .onTapGesture {
                                segue(coin: coin)
                            }
                    }
                }
                
                .listStyle(.plain)
                
                Spacer()
            }
        }
        
        .background(
            NavigationLink(destination: DetailLoadingView(coin: $selectCoin), isActive: $showDetailView, label: {
                EmptyView()
            })
        )
    }
    
    private func segue(coin: CoinModel) {
        selectCoin = coin
        showDetailView.toggle()
    }
}

#Preview {
    HomeView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
