//
//  Crypto.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2023/10/18.
//

import Foundation
import SwiftyJSON
import Security
import LocalAuthentication
import CryptoEth

struct sEthInfo{
    public let address: String
    public let privateKey: String
    public let mnemonic: String
    public func intoJson() -> JSON {
        return JSON(["address": self.address, "privateKey": self.privateKey, "mnemonic": self.mnemonic])
    }
    public static func fromRaw(info: EthInfo) -> Result<sEthInfo, CryptoError>{
        guard let addressPointer = info.address else {
            return .failure(CryptoError.libraryErr("Address is nil"))
        }
        let addressCString = UnsafeMutablePointer<CChar>(addressPointer)
        let addressString = String(cString: addressCString)
        
        guard let privateKeyPointer = info.private_key else {
            return .failure(CryptoError.libraryErr("privateKey is nil"))
        }
        let privateKeyCString = UnsafeMutablePointer<CChar>(privateKeyPointer)
        let privateKeyString = String(cString: privateKeyCString)
        
        guard let mnemonicPointer = info.mnemonic else {
            return .failure(CryptoError.libraryErr("privateKey is nil"))
        }
        let mnemonicCString = UnsafeMutablePointer<CChar>(mnemonicPointer)
        let mnemonicString = String(cString: mnemonicCString)
        return .success(sEthInfo(address: addressString, privateKey: privateKeyString, mnemonic: mnemonicString))
    }
    
    public static func new(json: JSON) -> Result<sEthInfo, CryptoError>{
        if let address = json["address"].string,
           let privateKey = json["privateKey"].string,
           let mnemonic = json["mnemonic"].string
        {
            return .success(sEthInfo(address: address, privateKey: privateKey, mnemonic: mnemonic))
        }
        return .failure(CryptoError.libraryErr("missing key `address` or `privateKey` in the json"))
    }
}

enum CryptoError: Swift.Error {
    case keyGenErr
    case keycahinErr(KeychainError)
    case libraryErr(String)
    public static func newLibraryErr(err: UnsafeMutablePointer<CChar>) -> CryptoError{
        let string = String(cString: err)
        free(err)
        return CryptoError.libraryErr(string)
    }
}

struct KeychainError: Error {
    enum ErrorKind{
        case noPassword
        case unexpectedPasswordData
        case unhandledError
    }
    let errCode: OSStatus
    let kind: ErrorKind
}

func generateEthSk(maybe_pwd: String?) -> Result<sEthInfo, CryptoError>{
    let pwd = (maybe_pwd ?? "").withCString { strdup($0) }

    let extInfo = generate_eth_private_key(pwd)
    if Int(extInfo.code.rawValue) != 0{
        free(extInfo.value.address)
        free(extInfo.value.private_key)
        free(extInfo.value.mnemonic)
        return .failure(CryptoError.newLibraryErr(err: extInfo.err_msg))
    } else{
        let info = sEthInfo.fromRaw(info: extInfo.value)
        free(extInfo.value.address)
        free(extInfo.value.private_key)
        free(extInfo.value.mnemonic)
        free(extInfo.err_msg)
        return info
    }
}

func storeIntoKeychain(id: String, ethInfo: sEthInfo) -> Result<(), CryptoError>{
//    let ethData = json.description.data(using: String.Encoding.utf8)!
    let ethData = ethInfo.intoJson().description.data(using: String.Encoding.utf8)!

    let flags: SecAccessControlCreateFlags = [.biometryCurrentSet, .devicePasscode, .or]
    let context = LAContext()
    context.localizedReason = "身分驗證以進行數位簽章"
    
    let access =
        SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                        flags,
                                        nil)!
    print("store eth sk in keychain, account id = ", id)
    let addquery: [String: Any] = [kSecClass as String: kSecClassInternetPassword ,
                                   kSecAttrAccount as String: id,
                                   kSecAttrServer as String: serverUrl,
                                   kSecValueData as String: ethData,
                                   kSecUseAuthenticationContext as String: context,
                                   kSecAttrAccessControl as String: access]
    
    SecItemDelete([kSecClass as String: kSecClassInternetPassword,
                   kSecAttrAccount as String: id,
                   kSecAttrServer as String: serverUrl] as CFDictionary)
    
    let status = SecItemAdd(addquery as CFDictionary, nil)
    guard status == errSecSuccess else { return .failure(CryptoError.keycahinErr( KeychainError(errCode: status, kind: .unhandledError)))}
    print("create sk status: ", status)
    
    return .success(())
}

func getEthInfo(id: String) -> Result<sEthInfo, CryptoError> {
    let context = LAContext()
    context.localizedReason = "身分驗證以進行數位簽章"
    let getquery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                   kSecAttrAccount as String: id,
                                   kSecAttrServer as String: serverUrl,
                                   kSecReturnAttributes as String: true,
                                   kSecReturnData as String: true,
                                   kSecUseAuthenticationContext as String: context]
    var item: CFTypeRef?

    let status = SecItemCopyMatching(getquery as CFDictionary, &item)
    guard status != errSecItemNotFound else { return .failure(CryptoError.keycahinErr(KeychainError(errCode: 0, kind: .noPassword)))}
    guard status == errSecSuccess else { return .failure(CryptoError.keycahinErr(KeychainError(errCode: status, kind: .unhandledError))) }
    print("status: ", status)
    guard let existingItem = item as? [String : Any],
        let secretData = existingItem[kSecValueData as String] as? Data,
        let ethJson = try? JSON(data: secretData)
    else {
        return .failure(CryptoError.keycahinErr(KeychainError(errCode: 0, kind: .unexpectedPasswordData)))
    }
    print(ethJson["address"].description)
    print(ethJson["privateKey"].description)
    return sEthInfo.new(json: ethJson)
}

func createTransaction(tx: sTx, rpc: String, base58Sk: String) -> Result<String, CryptoError>{
    let rpc = rpc.withCString { strdup($0) }
    let base58Sk = base58Sk.withCString { strdup($0) }

    let result = create_tx(tx.ext(), rpc, base58Sk)
    if Int(result.code.rawValue) != 0{
        free(result.value.bytes)
        return .failure(CryptoError.newLibraryErr(err: result.err_msg))
    } else{
        let signature = String(cString: result.value.bytes)
        print("signedTx", signature)
        free(result.value.bytes)
        free(result.err_msg)
        return .success(signature)
    }
}

struct sTx {
    var to: String
    var from: String
    var data: String
    var nonce: UInt64
    var value: UInt64
    var chainId: UInt64
    func ext() -> Tx{
        let to = self.to.withCString { strdup($0) }
        let from = self.from.withCString { strdup($0) }
        let data = self.data.withCString { strdup($0) }

        return Tx(to: to, from: from, data: data, nonce: self.nonce, value: self.value, chain_id: self.chainId)
    }
}
