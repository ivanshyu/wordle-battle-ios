//
//  FieldModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/12.
//

import Foundation
import SwiftyJSON

class FieldModel: ObservableObject {
    var squareViewArray = [SquareView]()
    var squareArray = [Square]()

    init(){
        squareViewArray = []
        for _ in 0...29 {
            var square = Square(char: "", color: .white)
            squareArray.append(square)
            squareViewArray.append(SquareView())
        }
    }
}
