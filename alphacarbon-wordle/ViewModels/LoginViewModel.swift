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
//        let _ = generateEthSk(maybe_pwd: nil).map {inf in
//            storeIntoKeychain(id: "111", ethInfo: inf)
//        }
//        getEthInfo(id: "111").map {inf in
//            print("get", inf)
//            let mockTx = sTx(to: "0xca1ba94a91b6549d67b475db88c3e035c5958b5a",
//                             from: inf.address,
//                             data: "0xa9059cbb0000000000000000000000001f94a717aff44bdc47719d559e39d21f092ea3ba00000000000000000000000000000000000000000000000000000000000a8750",
//                             nonce: 0,
//                             value: 0,
//                             chainId: 1337)
//            switch createTransaction(tx: mockTx, rpc: "http://192.168.50.147:8545", base58Sk: inf.privateKey){
//                case .success(let value):
//                    print("Success: \(value)")
//                case .failure(let error):
//                    print("Error: \(error)")
//            }
//            
//        }
        
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
        AF.request("\(serverUrl)/users/apple_user", method: .post, parameters: ["apple_id": appleId, "email": email, "name": name]).responseJSON{ response in
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
        AF.request("\(serverUrl)/users/apple_user?apple_id=\(appleId)").responseJSON{ response in
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
            AF.request("\(serverUrl)/users/update_fcm?apple_id=\(appleId)", method: .post, parameters: ["token": gFcmToken]).responseJSON{ response in
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
