//
//  ios_cryptoApp.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 23.12.2024.
//

import SwiftUI

@main
struct ios_cryptoApp: App {
    
    @StateObject var vm = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
                    .navigationBarHidden(true)
            }
            
            .environmentObject(vm)
        }
        
        
    }
}
