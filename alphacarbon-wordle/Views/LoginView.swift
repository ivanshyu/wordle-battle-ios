//
//  ContentView.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/15.
//

import SwiftUI

struct LoginView: View {
    var model = LoginInfo()
    @State var presentingModal = false
    
    var body: some View {
        ZStack{
            primaryColor.ignoresSafeArea()
            VStack {
                Spacer()
                Image("alpha-carbon").resizable()
                    .frame(width: 2/3 * fullScreenSize.width, height: 2/3 * fullScreenSize.width, alignment: .center) .clipShape(Capsule())
                
                
                Text("Alpha Carbon")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.vertical, between.height)
                
                Spacer()
                MainTextField(placeholder: Text("帳號"), text: model.account)
                
                
                Button("登入"){
                    
                }
                .buttonStyle(MainButton())
                .padding()
                
                
                HStack {
                    Text("尚未註冊帳戶嗎？")
                        .foregroundColor(labelColor)
                    Button("立即註冊"){
                        self.dismissBack()
                    }.foregroundColor(secondaryColor)
                        .sheet(isPresented: $presentingModal) {
                            //NavigationView{
                            RegisView(loginPresented: self)
                            //}
                        }
                }
                
                Spacer()
                
                Text("版本 " + appVersion)
                    .foregroundColor(labelColor)
                    .font(.footnote)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
        }
    }
}

protocol DismissView {
    func dismissBack()
}
protocol DismissAll {
    func dismissAll()
}

extension LoginView: DismissView{
    func dismissBack() {
        self.presentingModal == true ? (presentingModal=false) : (presentingModal=true)
    }
}
