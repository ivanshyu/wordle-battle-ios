//
//  MainTextField.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/15.
//

import Foundation
import SwiftUI

struct MainTextField : View{
    var placeholder: Text
    @State var text: String
    var type: UIKeyboardType = .asciiCapable
    
    var editingChanged: (Bool)->() = { _ in }
    var commit: ()->() = { }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .foregroundColor(inputHintColor)
                    .padding(.leading, gutter.width)
                
            }
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
                .padding(.leading, gutter.width)
                .foregroundColor(.white)
                .keyboardType(type)
                .disableAutocorrection(true)

        }
        .frame(width: fullViewSize.width, height: 50, alignment: .center)
        .background(inputBGColor)
        .cornerRadius(8)
    }
}

struct MainSecureField : View{
    var placeholder: Text
    @State var text: String
    var type: UIKeyboardType = .asciiCapable
    var commit: ()->() = { }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .foregroundColor(inputHintColor)
                    .padding(.leading, gutter.width)
                
            }
            SecureField("", text: $text, onCommit: commit)
                .padding(.leading, gutter.width)
                .foregroundColor(.white)
                .keyboardType(type)
                .disableAutocorrection(true)

        }
        .frame(width: fullViewSize.width, height: 50, alignment: .center)
        .background(inputBGColor)
        .cornerRadius(8)
    }
}
