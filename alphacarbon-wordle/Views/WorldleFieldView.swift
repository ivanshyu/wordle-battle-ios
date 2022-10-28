//
//  WorldleFieldView.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/11.
//

import Foundation
import SwiftUI

struct SquareView: View{
    @EnvironmentObject var square: Square
    let width = (fullScreenSize.width - 5*gutter.width)/5
    
    var body : some View {
        VStack{
            Spacer()
            Text(square.char)
                .bold()
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            Spacer()
        }.frame(width: width, height: width, alignment: .top)
        .foregroundColor(.white)
        .background(square.color)
        .cornerRadius(4)

    }
}

struct FieldView: View{
    @EnvironmentObject var field : FieldModel
    
    var body: some View{
        VStack{
            ForEach(0..<6){idx1 in
                HStack{
                    ForEach(0..<5){idx2 in
                        (field.squareViewArray[idx1*5 + idx2]).environmentObject(field.squareArray[idx1*5 + idx2])
                    }
                }
            }
            
        }.frame(width: fullViewSize.width, height: (fullScreenSize.width - 5*gutter.width)/5, alignment: .top)
        
    }
}
