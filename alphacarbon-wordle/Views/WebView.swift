//
//  WebView.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/5.
//

import Foundation
import SwiftUI
import WebKit
import SwiftyJSON

struct WebView: UIViewRepresentable {
    var webview: WKWebView?
    var url: URL
    
    init(web: WKWebView?, url: URL) {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        
        let uniqueProcessPool = WKProcessPool()
        webConfiguration.processPool = uniqueProcessPool
        self.webview = WKWebView(frame: .zero, configuration: webConfiguration)
        self.url = url
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WebView
        var timer: Timer? = nil
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        // Delegate methods go here
        //get data from local storage, and then parse it to desired structure
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            if self.timer == nil {
//                return
//            }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){_ in
                if self.parent.url == URL(string: wordle.link){
                    let script = "localStorage.getItem(\"nyt-wordle-moogle/ANON\")"
                    webView.evaluateJavaScript(script) { (data, error) in
                        if let error = error {
                            print ("localStorage.getitem('nyt-wordle-moogle/ANON') failed due to \(error)")
                            assertionFailure()
                            return
                        }
                        let encodedString = JSON(data as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
                        
                        let jsonData = JSON(encodedString)

                        wordleLocalGuess = jsonData["game"]["boardState"].arrayValue//.map({$0.stringValue})
                        
                        //record each char's index of solution
                        //eg. "tonic" => ["t": [0], "o": [1], .....]
                        //eg. "funny => ["n": [2, 3], ...]"
                        var ans: [Character: [Int]] = [:]
                        //record if last guess' index is evaluated

                        let solution = wordleAns
                        
                        //init the ans
                        var count = 0
                        for c in solution{
                            if ans[c] == nil{
                                ans[c] = [count]
                            } else{
                                ans[c]?.append(count)
                            }
                            count+=1
                        }
                        
                        if wordleLocalGuess.count == 0{
                            return
                        }
                        //evaluate each guess to ["correct", ... , "absent"] etc.
                        var guessCount = 0
                        for guess in wordleLocalGuess{
                            var isEvaluate = [EvaluateResult.none, EvaluateResult.none, EvaluateResult.none, EvaluateResult.none, EvaluateResult.none]
                            var ansHold = ans
                            let guessStr = guess.description
                            //correct
                            count = 0
                            for c in guessStr{
                                //
                                if (ansHold[c] ?? []).contains(count){
                                    // filter out from answer dictionary to avoid double calculating
                                    ansHold[c] = ansHold[c]?.filter{$0 != count}
                                    isEvaluate[count] = EvaluateResult.correct
                                }
                                count+=1
                            }
                            
                            count = 0
                            
                            //present & absent
                            for c in guessStr{
                                //present
                                if isEvaluate[count] == EvaluateResult.none && (ansHold[c] ?? []).count > 0{
                                    // pop one to avoid double calculating
                                    ansHold[c]?.popLast()
                                    isEvaluate[count] = EvaluateResult.present
                                }else if isEvaluate[count] == EvaluateResult.none{
                                    isEvaluate[count] = EvaluateResult.absent
                                }
                                count+=1
                            }
                        
                            wordleLocalEvaluations[guessCount] = isEvaluate.map{evaluateResultToStr(evaluateResult: $0)}
                            guessCount += 1
                        }
                        
                        //gameStatus
                        if jsonData["game"]["status"].description == "WIN"{
                            print("win")
                            wordleLocalGameStatus = GameStatus.win
                            self.timer!.invalidate()
                            print("webview: ", self.parent)
                        } else if jsonData["game"]["status"].description == "FAIL"{
                            print("lose")
                            wordleLocalGameStatus = GameStatus.lose
                            self.timer!.invalidate()
                        }
                    }
                }else if self.parent.url == URL(string: bopomofo.link){
                    let script = "localStorage.getItem(\"gameState\")"
                    webView.evaluateJavaScript(script) { (data, error) in
                        if let error = error {
                            print ("localStorage.getitem('gameState') failed due to \(error)")
                            assertionFailure()
                            return
                        }
                        let encodedString = JSON(data as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
                        
                        let jsonData = JSON(encodedString)
                        bopomofoLocalGuess = jsonData["guesses"].arrayValue
                        
                        //record each char's index of solution
                        var ans: [Character: [Int]] = [:]
                        //record if last guess' index is evaluated
                        
                        let solution = jsonData["solution"].description
                        
                        var count = 0
                        for c in solution{
                            if ans[c] == nil{
                                ans[c] = [count]
                            } else{
                                ans[c]?.append(count)
                            }
                            count+=1
                        }
                        
                        if bopomofoLocalGuess.count == 0{
                            return
                        }
                        let lastGuess: String = bopomofoLocalGuess.last?.description ?? ""
                        
                        //evaluate each guess to ["correct", ... , "absent"] etc.
                        var guessCount = 0
                        for guess in bopomofoLocalGuess{
                            var isEvaluate = [EvaluateResult.none, EvaluateResult.none, EvaluateResult.none, EvaluateResult.none, EvaluateResult.none]
                            var ansHold = ans

                            let guessStr = guess.description
                            //correct
                            count = 0
                            for c in guessStr{
                                if (ansHold[c] ?? []).contains(count){
                                    ansHold[c] = ansHold[c]?.filter{$0 != count}
                                    isEvaluate[count] = EvaluateResult.correct
                                }
                                count+=1
                            }
                            
                            count = 0
                            
                            //present & absent
                            for c in guessStr{
                                //present
                                if isEvaluate[count] == EvaluateResult.none && (ansHold[c] ?? []).count > 0{
                                    // pop one to prevent present repeatly
                                    ansHold[c]?.popLast()
                                    
                                    isEvaluate[count] = EvaluateResult.present
                                }else if isEvaluate[count] == EvaluateResult.none{
                                    isEvaluate[count] = EvaluateResult.absent
                                }
                                count+=1
                            }
//                            print("My evaluate for Bopomofo", guessStr, isEvaluate)
                            
                            bopomofoLocalEvaluations[guessCount] = isEvaluate.map{evaluateResultToStr(evaluateResult: $0)}
                            guessCount += 1
                        }
                        
                        //gameStatus
                        if lastGuess == solution{
                            bopomofoLocalAns = solution
                            print("win")
                            bopomofoLocalGameStatus = GameStatus.win
                            self.timer!.invalidate()
                            print("webview: ", self.parent)
                        } else if bopomofoLocalGuess.count == 6{
                            bopomofoLocalAns = solution
                            print("lose")
                            bopomofoLocalGameStatus = GameStatus.lose
                            self.timer!.invalidate()
                        }
                    }
                }
                
            }
            
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    func makeUIView(context: Context) -> WKWebView {
        return webview!
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.load(request)
    }
    
    
}

