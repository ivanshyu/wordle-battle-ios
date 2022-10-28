//
//  RegisView.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/16.
//

import Foundation
import SwiftUI

struct RegisChangeCodeView : View {
    var model = LoginInfo()
    var dismissAll: DismissAll

    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @GestureState private var dragOffset = CGSize.zero

    var body : some View {
        VStack {
            VStack {
                Spacer()
                
                Text("變更使用者代碼")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.vertical, gutter.height)
                Text("已找到您的用戶\n輸入新的使用者代碼以啟用帳戶")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Spacer()
            }.frame(width: fullScreenSize.width, height: 328, alignment: .center)
            
            
            MainTextField(placeholder: Text("變更使用者代碼"), text: model.account)
            
            Spacer()
            
            Button("變更使用者代碼並啟用"){
                dismissAll.dismissAll()
            }
            .buttonStyle(MainButton())
            .padding()
            .padding(.vertical , between.height)
        }
        .frame(maxWidth: fullScreenSize.width, maxHeight: .infinity)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action : {
            self.mode.wrappedValue.dismiss()

        }){
            HStack {
                Text("取消")
                Spacer()
            }
            .foregroundColor(.white)
        })
        .gesture(DragGesture().updating($dragOffset, body: { (value, state, transaction) in
                
                    if(value.startLocation.x < 20 && value.translation.width > 100) {
                        self.mode.wrappedValue.dismiss()
                    }
                    
                }))
        
    }
    
    
}
struct RegisChangeCodeView_Previews: PreviewProvider {
    struct Test: DismissAll {
        func dismissAll() {
            print("on click")
        }
    }
    static var previews: some View {
        NavigationView{
            RegisChangeCodeView(dismissAll: Test())
            
        }
    }
}
