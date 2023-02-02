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
import Alamofire



class BattleModel: ObservableObject{
    @Published var connectionOpt: ConnectionMetaData!
    var manager: SocketManager!
    var socket: SocketIOClient!
    let group = DispatchGroup()
    @Published var userCount = 0
    @Published var wordleState = WordleState.loading
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
    
    init(connectionOpt: ConnectionMetaData){
        self.connectionOpt = connectionOpt
        let competitor = Competitor(id: connectionOpt.id, name: connectionOpt.name)
        self.competitors.append(competitor)
        self.nowCompetitor = competitor
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        manager = SocketManager(socketURL: URL(string: "http://140.119.163.70:3030")!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket.connect()
        getTodayAns(){ ans in
            wordleAns = ans
        }
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.wordleState = WordleState.waiting
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
            // handle when user reconnect, ignore this event
            if self.wordleState != WordleState.Prepare{
                return
            }
            print("start_wordle recv", data)
            guard data[0] as! Bool else{
                print("err while parsing data")
                return
            }
            self.wordleState = WordleState.Start
            /// #NOTE: When user reconnect, timer won't be null
            if self.timer == nil {
                print("timer is not nil")
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
                    
                    (self.mins, self.secs) = timeSequence(mins: self.mins, secs: self.secs)
                    if self.wordleState == WordleState.End {
                        self.timer?.invalidate()
                    }else if self.wordleState == WordleState.Submit {
                        return
                    }
                    
                    //self.emit.localEvaluation
                    self.evaluationWordle()

                    self.gameStatus = wordleLocalGameStatus
                    if self.gameStatus == GameStatus.win{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [self.mins, self.secs])
                            print("chage state to submit, time: \(self.submitTime)")
                        }
                        self.completeWordle()

                    }else if self.gameStatus == GameStatus.lose{
                        if self.submitTime == ""{
                            self.submitTime = String(format: "%02d:%02d", arguments: [15, 00])
                            print("chage state to submit, time: \(self.submitTime)")
                        }
                        self.completeWordle()

                    }
                }
                //after reconnect
            } else if wordleLocalGameStatus == GameStatus.win || wordleLocalGameStatus == GameStatus.lose{
                self.completeWordle()
            }
            

        }
        socket.on("wordle_evaluation"){data, ack in
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
        
        socket.on("finish_wordle"){data, ack in
            self.result = JSON(data[0]).arrayValue
            self.wordleState = WordleState.End
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
        if wordleState == WordleState.loading{
            return
        }
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
    
        let hold : [JSON] = wordleLocalEvaluations.map{($0 ?? []).count == 0 ? JSON(NSNull()) : JSON($0!)}
        
        wordleLocalGuessForEvaluation = wordleLocalGuess.map{$0.stringValue}
        
        while wordleLocalGuessForEvaluation.count<6{
            wordleLocalGuessForEvaluation.append("")
        }
        
        let params = ["name": self.connectionOpt.name, "id":  self.connectionOpt.id, "evaluations": [hold.description, wordleLocalGuessForEvaluation]] as [String : Any]
        self.socket.emit("wordle_evaluation", params)
        
    }
    
    func completeWordle(){
        print("complete")
        let params = ["time": submitTime, "name": self.connectionOpt.name, "id":  self.connectionOpt.id]
        self.socket.emit("complete_wordle", params)
        if self.wordleState != WordleState.End{
            self.wordleState = WordleState.Submit
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
    
    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        print("Enter Background")
        appDidEnterBackgroundDate = Date()
        if wordleState == WordleState.End || wordleState == WordleState.Submit{
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
        if wordleState == WordleState.Start || wordleState == WordleState.Submit{
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
