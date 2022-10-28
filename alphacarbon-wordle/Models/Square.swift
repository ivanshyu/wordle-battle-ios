//
//  Square.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/12.
//

import Foundation
import SwiftUI

class Square: ObservableObject{
    @Published var char: String
    @Published var color: Color
    init(char: String, color: Color){
        self.char = char
        self.color = color
    }
}
