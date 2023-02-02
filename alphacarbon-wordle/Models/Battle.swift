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
    public var id: String
    public var name: String
}
enum WordleState{
    case loading
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

var wordleAns = ""

/// #NOTE: Local means these status are created/updated from local, they are states for the local user
var wordleLocalGameStatus = GameStatus.inProgress
var wordleLocalGuess: [JSON] = []
var wordleLocalGuessForEvaluation: [String] = []
var wordleLocalEvaluations: [[String]?] = [nil, nil, nil, nil, nil, nil]

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
    while secs > 59{
        secs -= 59
        mins += 1
    }
    
    return (mins, secs)
}

struct Competitor {
    var id: String
    var name: String
}
