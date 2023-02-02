//
//  BopomofoBattleModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/10.
//

import Foundation
import SocketIO
import Dispatch
import SwiftyJSON
import UIKit

class BopomofoBattleModel: ObservableObject{
    @Published var connectionOpt: ConnectionMetaData!
    var manager: SocketManager!
    var socket: SocketIOClient!
    let group = DispatchGroup()
    @Published var userCount = 0
    @Published var bopomofoState = WordleState.loading
    @Published var result : [JSON] = []
    
    @Published var webview: WebView = WebViewModel().bopomofoWebview
    @Published var gameStatus = GameStatus.inProgress
    //from other people
    @Published var evaluations : [String: JSON] = [:]
    
    var timer: Timer? = nil
    var heartbeatTimer: Timer? = nil

    @Published var secs = 0
    @Published var mins = 0
    @Published var submitTime = ""
    
    var appDidEnterBackgroundDate: Date!

    var competitors: [Competitor] = []
    var competitorIdx = 0
    
    @Published var nowCompetitor: Competitor!
    
    let startTime = Date()

    init(connectionOpt: ConnectionMetaData){
        self.connectionOpt = connectionOpt
        let competitor = Competitor(id: connectionOpt.id, name: connectionOpt.name)
        self.competitors.append(competitor)
        self.nowCompetitor = competitor

        manager = SocketManager(socketURL: URL(string: "http://140.119.163.70:3030")!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket.connect()
        
        socket.on(clientEvent: .connect) {data, ack in
            print("bopomofo socket connected")
            self.bopomofoState = WordleState.waiting
        }
        socket.on("total_user_bopomofo"){data, ack in
            print("total_user_bopomofo recv: ", data)
            guard let count = data[0] as? Int else{
                print("err while parsing data")
                return
            }
            self.userCount = count
        }
        socket.on("start_bopomofo"){data, ack in
            print("start_bopomofo recv", data)
            guard data[0] as! Bool else{
                print("err while parsing data")
                return
            }
            self.bopomofoState = WordleState.Start
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
                    (self.mins, self.secs) = timeSequence(mins: self.mins, secs: self.secs)
                    
                    if self.bopomofoState == WordleState.End {
                        self.timer?.invalidate()
                    }else if self.bopomofoState == WordleState.Submit {
                        return
                    }
                    
                    self.evaluationBopomofo()
                    
                    self.gameStatus = bopomofoLocalGameStatus
                    if self.gameStatus == GameStatus.win{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [self.mins, self.secs])
                            print("chage state to submit, time: \(self.submitTime)")
                            self.completeBopomofo()
                        }
                    }else if self.gameStatus == GameStatus.lose{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [15, 00])
                            print("chage state to submit, time: \(self.submitTime)")
                            self.completeBopomofo()
                        }
                    }
                }
            } else if bopomofoLocalGameStatus == GameStatus.win || bopomofoLocalGameStatus == GameStatus.lose{
                print("timer isn't nil")
                self.completeBopomofo()
            }
            
        }
        socket.on("bopomofo_evaluation"){data, ack in
            //print(data)
            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
            let json = JSON(encodedString)
            
            self.evaluations[json["id"].description] = json
            
            if self.competitors.filter({$0.id == json["id"].description}).count == 0{
                self.competitors.append(Competitor(id: json["id"].description, name: json["name"].description))
            }
        }
        
//        socket.on("complete_bopomofo"){data, ack in
//            //print(data)
//            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
//            let json = JSON(encodedString)
//        }
        socket.on("finish_bopomofo"){data, ack in
            print("finish_bopomofo recv", data)

            self.result = JSON(data[0]).arrayValue
            self.bopomofoState = WordleState.End
        }
    }
    
    func connect(){
        if bopomofoState == WordleState.loading{
            return
        }
        print("in self.connect")
        self.bopomofoState = WordleState.Prepare
        self.socket.emit("user_connect_bopomofo", ["userId": self.connectionOpt.id])
        
        //if it does not exist, add into competitors
        if self.heartbeatTimer == nil {
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true){_ in
                self.heartBeat()
            }
        }
    }
    
    func startBopomofo(complete: @escaping (_ status: Bool) -> Void){
        self.socket.emit("start_bopomofo", [])
        
    }
    
    func evaluationBopomofo(){
        let hold : [JSON] = bopomofoLocalEvaluations.map{($0 ?? []).count == 0 ? JSON(NSNull()) : JSON($0!)}
        
        bopomofoLocalGuessForEvaluation = bopomofoLocalGuess.map{$0.stringValue}
        
        while bopomofoLocalGuessForEvaluation.count<6{
            bopomofoLocalGuessForEvaluation.append("")
        }
        
        let params = ["name": self.connectionOpt.name, "id":  self.connectionOpt.id, "evaluations": [hold.description, bopomofoLocalGuessForEvaluation]] as [String : Any]
        self.socket.emit("bopomofo_evaluation", params)
       //print(params)
        
    }
    
    func completeBopomofo(){
        let params = ["time": submitTime, "name": self.connectionOpt.name, "id":  self.connectionOpt.id]
        self.socket.emit("complete_bopomofo", params)
        if self.bopomofoState != WordleState.End{
            self.bopomofoState = WordleState.Submit
        }
    }
    func heartBeat(){
        print("bopomofo heart beat")
        self.socket.emit("bopomofo_heartbeat", ["userId": self.connectionOpt.id])

    }
    func closeSocket(){
        socket.disconnect()
    }
    func reconnect(){
        socket.connect()
        if bopomofoState != WordleState.waiting{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.socket.emit("user_connect_bopomofo", ["userId": self.connectionOpt.id])
            }
        }
    }

    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        appDidEnterBackgroundDate = Date()
        if bopomofoState == WordleState.End || bopomofoState == WordleState.Submit{
            self.timer = nil
        }
    }

    @objc func applicationWillEnterForeground(_ notification: NotificationCenter) {
//reconnect()
        guard let previousDate = appDidEnterBackgroundDate else { return }
        let calendar = Calendar.current
        let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
        let seconds = difference.second!
        if bopomofoState == WordleState.Start{
            secs += seconds
        }
        
        // judge if need to reopen app
        if let sec = calendar.dateComponents([.second], from: previousDate, to: Date()).second{
            print("sec difference: \(sec)")
            if sec >= 5{
                exit(0)
            }
        }
    }
    
    func nextCompetitor() -> Competitor{
        if competitorIdx + 1 >= competitors.count {
            competitorIdx = 0
        }else{
            competitorIdx+=1
        }
        self.nowCompetitor = competitors[competitorIdx]
        return competitors[competitorIdx]
    }
    
    func prevCompetitor() -> Competitor{
        if competitorIdx - 1 < 0 {
            competitorIdx = competitors.count - 1
        }else{
            competitorIdx-=1
        }
        self.nowCompetitor = competitors[competitorIdx]
        return competitors[competitorIdx]
    }
    deinit{
        //closeSocket()
    }
}
