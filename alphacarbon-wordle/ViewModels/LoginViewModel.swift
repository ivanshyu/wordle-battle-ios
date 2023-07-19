//
//  LoginViewModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/12/28.
//

import Foundation
import Alamofire
import SwiftyJSON
import AuthenticationServices

class LoginViewModel: ObservableObject {
    let isTest = false
    @Published var isLogin = false
    @Published var email = ""
    @Published var name = ""
    init(){
        if isTest{
            self.isLogin = true
            self.email = "tester@gggggg"
            self.name = "tester"
            return
        }
        if let appleId = UserDefaults().string(forKey: "appleId"){
            print("appleId ", appleId)
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: appleId) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    self.login(appleId: appleId)
                default:
                    break
                }
            }
        }
    }
    func register(appleId: String, email: String, name: String, complete: @escaping (_ status: Bool) -> Void) {
        AF.request("http://140.119.163.70:3030/users/apple_user", method: .post, parameters: ["apple_id": appleId, "email": email, "name": name]).responseJSON{ response in
            switch response.result{
            case .success(let value):
                let response = JSON(value)
                print(response)
                complete(response["status"].boolValue)
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func login(appleId: String) {
        AF.request("http://140.119.163.70:3030/users/apple_user?apple_id=\(appleId)").responseJSON{ response in
            switch response.result{
            case .success(let value):
                let response = JSON(value)
                print(response)
                if response["status"].boolValue {
                    print(response["status"].boolValue)
                    UserDefaults().setValue(appleId, forKey: "appleId")

                    self.isLogin = true
                    self.email = response["email"].description
                    self.name = response["name"].description
                }
            case .failure(let error):
                print(error)
                break
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("gFcmToken: ", gFcmToken)
            AF.request("http://140.119.163.70:3030/users/update_fcm?apple_id=\(appleId)", method: .post, parameters: ["token": gFcmToken]).responseJSON{ response in
                switch response.result{
                case .success(_):
                    print(response)
                case .failure(let error):
                    print(error)
                    break
                }
            }
        }
    }
}
