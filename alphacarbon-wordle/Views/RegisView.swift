//
//  RegisView.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/16.
//

import Foundation
import SwiftUI

struct RegisView : View {
    var loginPresented: DismissView
    var model = LoginInfo()
    @State private var action: Int? = 0
    @State var presentingModal = false

    var body : some View {
        NavigationView{
            VStack {
                VStack {
                    Spacer()
                    
                    Text("註冊帳戶")
                        .foregroundColor(.white)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.vertical, gutter.height)
                    Text("輸入帳號以完成註冊程序")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Spacer()
                }.frame(width: fullScreenSize.width, height: fullScreenSize.height/3, alignment: .center)
                
                
                MainTextField(placeholder: Text("登入帳號"), text: model.account)
                MainTextField(placeholder: Text("顯示名稱"), text: model.account)

                                
                Spacer()
                
                NavigationLink(
                    destination: RegisChangeCodeView(dismissAll: self),
                    tag: 1,
                    selection: $action,
                    label: {EmptyView()})
                
                
                Button("註冊帳戶"){
                    self.action = 1
                }
                .buttonStyle(MainButton())
                .padding()
                .padding(.vertical , between.height)
                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(primaryColor)
            .edgesIgnoringSafeArea(.all)
            
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    HStack {
                        Button("取消"){
                            loginPresented.dismissBack()
                            
                        }
                        Spacer()
                    }
                    .foregroundColor(.white)
                }
            })
            
        }
        
    }
    
}
struct RegisView_Previews: PreviewProvider {
    struct Test: DismissView {
        func dismissBack() {
            print("on click")
        }
    }
    static var previews: some View {
        RegisView(loginPresented: Test())
    }
}
extension RegisView: DismissView{
    func dismissBack() {
        self.presentingModal == true ? (presentingModal=false) : (presentingModal=true)
    }
}

extension RegisView: DismissAll{
    func dismissAll() {
        loginPresented.dismissBack()
    }
}
