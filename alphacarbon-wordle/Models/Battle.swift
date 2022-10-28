//
//  Battle.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/8.
//

import Foundation
import UIKit
import SwiftyJSON

struct ConnectionMetaData{
    public var id: String = UIDevice.current.identifierForVendor!.uuidString

}
enum WordleState{
    case waiting
    case Prepare
    case Start
    case Submit
    case End
}
enum GameStatus{
    case inProgress
    case win
    case lose
}
var battleNameToId: [String: String] = [:]

var wordleLocalGameStatus = GameStatus.inProgress
var wordleLocalGuess: [String] = []
var wordleLocalEvaluations: [JSON] = []
var wordleLocalAns:String = ""

var bopomofoLocalGameStatus = GameStatus.inProgress
var bopomofoLocalGuess: [JSON] = []
var bopomofoLocalGuessForEvaluation: [String] = []
var bopomofoLocalEvaluations: [[String]?] = [nil, nil, nil, nil, nil, nil]
var bopomofoLocalAns:String = ""

enum EvaluateResult{
    case correct
    case present
    case absent
    case none //not yet evaluate
}
func evaluateResultToStr(evaluateResult: EvaluateResult) -> String{
    switch evaluateResult{
        case .correct:
            return "correct"
        case .absent:
            return "absent"
        case .present:
            return "present"
        case .none:
            return "error"
    }
}


func timeSequence(mins: Int, secs: Int) -> (Int, Int){
    var secs = secs
    var mins = mins
    secs += 1
    if secs > 59{
        secs = 0
        mins += 1
    }
    
    return (mins, secs)
}

