//
//  ContentView.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/15.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject private var loginViewModel = LoginViewModel()

    var model = LoginInfo()
    @State var presentingModal = false
    var body: some View {
        if loginViewModel.isLogin {
            TabbarView(connectionMetaData: ConnectionMetaData(id: loginViewModel.email, name: loginViewModel.name))
        } else{
            ZStack{
                primaryColor.ignoresSafeArea()
                VStack {
                    Spacer()
                    Image("carbon").resizable()
                        .frame(width: 1/2 * fullScreenSize.width, height: 1/2 * fullScreenSize.width, alignment: .center).clipShape(Circle())
                    
                    
                    Text("Alpha Carbon")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.vertical, between.height)
                    Spacer()
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                                
                            case .success(let authResults):
                                
                                switch authResults.credential {
                                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                                    
                                    if let email = appleIDCredential.email, let fullName = appleIDCredential.fullName {
                                        print("regis: \(email), \(fullName), \(appleIDCredential.user)")
                                        
                                        loginViewModel.register(appleId: appleIDCredential.user, email: email, name: fullName.givenName ?? ""){ status in
                                            print(status)
                                            print("login: \(appleIDCredential.user)")
                                            
                                            if status {
                                                loginViewModel.login(appleId: appleIDCredential.user)
                                            }
                                        }
                                    }else{
                                        print("login: \(appleIDCredential.user)")
                                        loginViewModel.login(appleId: appleIDCredential.user)
                                    }
                                    
                                case let passwordCredential as ASPasswordCredential:
                                    let username = passwordCredential.user
                                    let password = passwordCredential.password
                                    print(username, password)
                                    
                                default:
                                    break
                                }
                            case .failure(let error):
                                print("failure", error)
                                
                            }
                        }
                    ).signInWithAppleButtonStyle(.white)
                        .frame(width: fullViewSize.width, height: 50)
                    
                    //                MainTextField(placeholder: Text("帳號"), text: model.account)
                    
                    //                Button("登入"){
                    //
                    //
                    //                }
                    //                .buttonStyle(MainButton())
                    //                .padding()
                    
                    
                    //                H1Stack {
                    //                    Text("尚未註冊帳戶嗎？")
                    //                        .foregroundColor(labelColor)
                    //                    Button("立即註冊"){
                    //                        self.dismissBack()
                    //                    }.foregroundColor(secondaryColor)
                    //                        .sheet(isPresented: $presentingModal) {
                    //                            //NavigationView{
                    //                            RegisView(loginPresented: self)
                    //                            RegisView(loginPresented: self)
                    //                            //}
                    //                        }
                    //                }
                    
                    Spacer()
                    
                    Text("版本 " + appVersion)
                        .foregroundColor(labelColor)
                        .font(.footnote)
                }
            }
        }
    }
    func onMainThread(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
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
