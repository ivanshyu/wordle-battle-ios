//
//  MainButton.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/16.
//

import Foundation
import SwiftUI

struct MainButton: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: fullViewSize.width, height: 50, alignment: .center)
            .background(secondaryColor)
            .foregroundColor(primaryColor)
            .font(.headline.bold())
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

struct SecondaryButton: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: fullViewSize.width, height: 50, alignment: .center)
            .background(Color(UIColor(red:84/255, green:138/255, blue:171/255, alpha:1)))
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.headline.bold())
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }
}
