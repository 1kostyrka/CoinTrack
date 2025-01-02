//
//  ButtonStyle.swift
//  ios-crypto
//
//  Created by Ivan Kostyrka on 30.12.2024.
//

import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: 50)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Color.gray : Color.theme.accent)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
