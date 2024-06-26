//
//  GenericBattleModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2023/2/2.
//

import Foundation
import SocketIO
import Dispatch
import SwiftyJSON
import Alamofire



class GenericBattleModel: ObservableObject{
    @Published var connectionOpt: ConnectionMetaData!
    var type: BattleType!

    var manager: SocketManager!
    var socket: SocketIOClient!
    let group = DispatchGroup()
    @Published var userCount = 0
    @Published var state = WordleState.loading
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
    
    var competitors: [Competitor] = []
    var competitorIdx = 0
        
    @Published var nowCompetitor: Competitor!
    
    init(connectionOpt: ConnectionMetaData, type: BattleType){
        self.connectionOpt = connectionOpt
        self.type = type

        let competitor = Competitor(id: connectionOpt.id, name: connectionOpt.name)
        self.competitors.append(competitor)
        self.nowCompetitor = competitor
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        manager = SocketManager(socketURL: URL(string: serverUrl)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket.connect()
        
        if type == .Wordle{
            getTodayAns(){ ans in
                wordleAns = ans
            }
        }
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.state = WordleState.waiting
        }
        socket.on("total_user_\(type.display())"){data, ack in
            print("total_user recv: ", data)
            guard let count = data[0] as? Int else{
                print("err while parsing data")
                return
            }
            self.userCount = count
        }
        socket.on("start_\(type.display())"){data, ack in
            // handle when user reconnect, ignore this event
            if self.state != WordleState.Prepare{
                return
            }
            print("start_\(type.display()) recv", data)
            guard data[0] as! Bool else{
                print("err while parsing data")
                return
            }
            self.state = WordleState.Start
            /// #NOTE: When user reconnect, timer won't be null
            if self.timer == nil {
                print("timer is not nil")
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
                    
                    (self.mins, self.secs) = timeSequence(mins: self.mins, secs: self.secs)
                    if self.state == WordleState.End {
                        self.timer?.invalidate()
                    }else if self.state == WordleState.Submit {
                        return
                    }
                    
                    //self.emit.localEvaluation
                    self.evaluation()
                    
                    switch type {
                    case .Wordle:
                        self.gameStatus = wordleLocalGameStatus
                    case .Bopomofo:
                        self.gameStatus = bopomofoLocalGameStatus
                    }
                    
                    if self.gameStatus == GameStatus.win{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [self.mins, self.secs])
                            print("chage state to submit, time: \(self.submitTime)")
                        }
                        self.complete()

                    }else if self.gameStatus == GameStatus.lose{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [15, 00])
                            print("chage state to submit, time: \(self.submitTime)")
                        }
                        self.complete()

                    }
                }
                //after reconnect
            } else if type == BattleType.Wordle && (wordleLocalGameStatus == GameStatus.win || wordleLocalGameStatus == GameStatus.lose){
                self.complete()
            }  else if type == BattleType.Bopomofo && (bopomofoLocalGameStatus == GameStatus.win || bopomofoLocalGameStatus == GameStatus.lose){
                self.complete()
            }
            

        }
        socket.on("\(type.display())_evaluation"){data, ack in
            //print(data)
            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
            let json = JSON(encodedString)
            
            self.evaluations[json["id"].description] = json
            
            //if it does not exist, add into competitors
            if self.competitors.filter({$0.id == json["id"].description}).count == 0{
                self.competitors.append(Competitor(id: json["id"].description, name: json["name"].description))
            }
        }
        
//        socket.on("complete_wordle"){data, ack in
//            let encodedString = JSON(data[0]).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
//            let json = JSON(encodedString)
//
//        }
        
        socket.on("finish_\(type.display())"){data, ack in
            self.result = JSON(data[0]).arrayValue
            self.state = WordleState.End
        }
    }
    func getTodayAns(complete: @escaping (_ ans: String) -> Void){
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        AF.request("https://www.nytimes.com/svc/wordle/v2/\(todayString).json").responseJSON{ response in
            switch response.result{
            case .success(let value):
                let response = JSON(value)
                complete(response["solution"].description)
            case .failure(let error):
                print(error)
                break
            }
        }

    }
    
    func connect(){
        if state == WordleState.loading{
            return
        }
        state = WordleState.Prepare
        self.socket.emit("user_connect_\(type.display())", ["userId": self.connectionOpt.id])
        if self.heartbeatTimer == nil {
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true){_ in
                self.heartBeat()
            }
        }
    }
    
    func start(complete: @escaping (_ status: Bool) -> Void){
        self.socket.emit("start_\(type.display())", [])
        
    }
    
    func evaluation(){
        switch type {
        case .Wordle:
            let hold : [JSON] = wordleLocalEvaluations.map{($0 ?? []).count == 0 ? JSON(NSNull()) : JSON($0!)}
            
            wordleLocalGuessForEvaluation = wordleLocalGuess.map{$0.stringValue}
            
            while wordleLocalGuessForEvaluation.count<6{
                wordleLocalGuessForEvaluation.append("")
            }
            let params = ["name": self.connectionOpt.name, "id":  self.connectionOpt.id, "evaluations": [hold.description, wordleLocalGuessForEvaluation]] as [String : Any]
            self.socket.emit("\(type.display())_evaluation", params)
            
        case .Bopomofo:
            let hold : [JSON] = bopomofoLocalEvaluations.map{($0 ?? []).count == 0 ? JSON(NSNull()) : JSON($0!)}
            
            bopomofoLocalGuessForEvaluation = bopomofoLocalGuess.map{$0.stringValue}
            
            while bopomofoLocalGuessForEvaluation.count<6{
                bopomofoLocalGuessForEvaluation.append("")
            }
            let params = ["name": self.connectionOpt.name, "id":  self.connectionOpt.id, "evaluations": [hold.description, bopomofoLocalGuessForEvaluation]] as [String : Any]
            self.socket.emit("\(type.display())_evaluation", params)
            
        case .none:
            return
        }
        
    }
    
    func complete(){
        print("complete")
        let params = ["time": submitTime, "name": self.connectionOpt.name, "id":  self.connectionOpt.id]
        self.socket.emit("complete_\(type.display())", params)
        if self.state != WordleState.End{
            self.state = WordleState.Submit
        }
    }
    
    func heartBeat(){
        print("heart beat")
        self.socket.emit("\(type.display())_heartbeat", ["userId": self.connectionOpt.id])
    }
    func closeSocket(){
        socket.disconnect()
    }
    func reconnect(){
        socket.connect()
        if state != WordleState.waiting{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.socket.emit("user_connect_\(self.type.display())", ["userId": self.connectionOpt.id])
            }
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        print("Enter Background")
        appDidEnterBackgroundDate = Date()
        if state == WordleState.End || state == WordleState.Submit{
            self.timer = nil
        }
    }

    @objc func applicationWillEnterForeground(_ notification: NotificationCenter) {
//        reconnect()
        guard let previousDate = appDidEnterBackgroundDate else { return }
        let calendar = Calendar.current
        let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
        let seconds = difference.second!
        print("Enter Foreground, Delay: \(seconds) secs")
        if state == WordleState.Start || state == WordleState.Submit{
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
