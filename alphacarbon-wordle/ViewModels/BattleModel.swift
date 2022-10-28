//
//  BattleModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/8.
//

import Foundation
import SocketIO
import Dispatch
import SwiftyJSON

class BattleModel: ObservableObject{
    @Published var connectionOpt = ConnectionMetaData()
    var manager: SocketManager!
    var socket: SocketIOClient!
    let group = DispatchGroup()
    @Published var userCount = 0
    @Published var wordleState = WordleState.waiting
    @Published var result : [JSON] = []
    
    @Published var gameStatus = GameStatus.inProgress
    //from other people
    @Published var evaluations : [String: JSON] = [:]
    var timer: Timer? = nil
    var heartbeatTimer: Timer? = nil

    @Published var secs = 0
    @Published var mins = 0
    @Published var submitTime = ""
    
    var appDidEnterBackgroundDate: Date!
    
    var competitors: [String] = []
    var competitorIdx = 0

    init(){
        self.competitors.append(UIDevice.current.name)
        battleNameToId[UIDevice.current.name] = self.connectionOpt.id

        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        manager = SocketManager(socketURL: URL(string: "http://140.119.163.70:3030")!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket.connect()
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            
        }
        socket.on("total_user_wordle"){data, ack in
            print("total_user recv: ", data)
            guard let count = data[0] as? Int else{
                print("err while parsing data")
                return
            }
            self.userCount = count
        }
        socket.on("start_wordle"){data, ack in
            if self.wordleState != WordleState.Prepare{
                return
            }
            print("start_wordle recv", data)
            guard data[0] as! Bool else{
                print("err while parsing data")
                return
            }
            self.wordleState = WordleState.Start
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){_ in
                    (self.mins, self.secs) = timeSequence(mins: self.mins, secs: self.secs)

                    //self.emit.localEvaluation
                    self.evaluationWordle()

                    self.gameStatus = wordleLocalGameStatus
                    if self.gameStatus == GameStatus.win{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [self.mins, self.secs])
                            print("chage state to submit, time: \(self.submitTime)")
                            self.wordleState = WordleState.Submit
                            self.completeWordle(){json in
                            }
                        }
                        if self.wordleState == WordleState.End {
                            self.timer?.invalidate()
                        }
                    }else if self.gameStatus == GameStatus.lose{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [15, 00])
                            print("chage state to submit, time: \(self.submitTime)")
                            self.wordleState = WordleState.Submit
                            self.completeWordle(){json in
                            }
                        }
                        if self.wordleState == WordleState.End {
                            self.timer?.invalidate()
                        }
                    }
                }
            }
            

        }
        socket.on("wordle_evaluation"){data, ack in
            //print(data)
            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
            let json = JSON(encodedString)
            
            self.evaluations[json["id"].description] = json
            if !self.competitors.contains(json["name"].description){
                self.competitors.append(json["name"].description)
                battleNameToId[json["name"].description] = json["id"].description
            }
        }
        
        socket.on("finish_wordle"){data, ack in
            print("finish_wordle recv", data)

            self.result = JSON(data[0]).arrayValue
            self.wordleState = WordleState.End
        }
    }
    
    func connect(){
        print("in self.connect")
        wordleState = WordleState.Prepare
        self.socket.emit("user_connect_wordle", ["userId": self.connectionOpt.id])
        if self.heartbeatTimer == nil {
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true){_ in
                self.heartBeat()
            }
        }
    }
    
    func startWordle(complete: @escaping (_ status: Bool) -> Void){
        self.socket.emit("start_wordle", [])
        
    }
    
    func evaluationWordle(){
        let params = ["name": UIDevice.current.name, "id":  self.connectionOpt.id, "evaluations": [wordleLocalEvaluations.description, wordleLocalGuess]] as [String : Any]
        self.socket.emit("wordle_evaluation", params)
       //print(params)
        
    }
    
    func completeWordle(complete: @escaping (_ json: JSON) -> Void){
        let params = ["time": submitTime, "name": UIDevice.current.name, "id":  self.connectionOpt.id]
        self.socket.emit("complete_wordle", params)
       
        socket.on("complete_wordle"){data, ack in
            //print(data)
            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
            let json = JSON(encodedString)
            
            if let _ = json["name"].string {
                complete(json)
            } else {
                complete(JSON())
            }
        }
    }
    
    func heartBeat(){
        print("heart beat")
        self.socket.emit("wordle_heartbeat", ["userId": self.connectionOpt.id])
    }
    func closeSocket(){
        socket.disconnect()
    }
    func reconnect(){
        socket.connect()
        if wordleState != WordleState.waiting{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.socket.emit("user_connect_wordle", ["userId": self.connectionOpt.id])
            }
        }
    }
    
//    @objc func applicationDidBecomeActive(_ notification: NotificationCenter) {
//        print("Unlock")
//        reconnect()
//    }
    
    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        print("Enter Background")
        appDidEnterBackgroundDate = Date()
    }

    @objc func applicationWillEnterForeground(_ notification: NotificationCenter) {
        reconnect()
        guard let previousDate = appDidEnterBackgroundDate else { return }
        let calendar = Calendar.current
        let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
        let seconds = difference.second!
        print("Enter Foreground, Delay: \(seconds) secs")
        if wordleState == WordleState.Start || wordleState == WordleState.Submit{
            secs += seconds
        }
    }
    
    func nowCompetitor() -> String{
        return competitors[competitorIdx]
    }
    
    func nextCompetitor() -> String{
        if competitorIdx + 1 >= competitors.count {
            competitorIdx = 0
        }else{
            competitorIdx+=1
        }
        return competitors[competitorIdx]
    }
    
    func prevCompetitor() -> String{
        if competitorIdx - 1 < 0 {
            competitorIdx = competitors.count - 1
        }else{
            competitorIdx-=1
        }
        return competitors[competitorIdx]
    }
    
    deinit{
        closeSocket()
    }
}
