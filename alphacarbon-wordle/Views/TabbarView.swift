//
//  TabbarView.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/5.
//

import Foundation
import SwiftUI
import SwiftyJSON

struct TabbarView: View {
    @StateObject private var battle = BattleModel()
    @StateObject private var bopomofoBattle = BopomofoBattleModel()
    init(){
        let image = UIImage.gradientImageWithBounds(
            bounds: CGRect( x: 0, y: 0, width: UIScreen.main.scale, height: 10),
            colors: [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.1).cgColor
            ]
        )
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemGray6
        
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = image
        
        UITabBar.appearance().standardAppearance = appearance
        
    }
    var body: some View {
        
        VStack{
            TabView {
                WordleView().environmentObject(battle).tabItem {
                    Label("wordle", systemImage: "w.square.fill")
                }.background(primaryColor)
                BopomofoView().environmentObject(bopomofoBattle).tabItem {
                    Label("注得了", systemImage: "b.square.fill")
                }.background(primaryColor)
            }.accentColor(primaryColor).shadow(color: primaryColor, radius: 10, x: 100, y: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.all)
        
        
    }
}
struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabbarView()
        }
    }
}

struct WordleView: View {
    @State private var showWebView = false
    @EnvironmentObject var battle : BattleModel
    var isShowing: Bool = true
    
    @State private var competitors: [JSON] = []
    
    @State var gameStatus = GameStatus.inProgress
    
    @StateObject private var field = FieldModel()
    @State var timer: Timer? = nil
    
    @State var userFieldId : String = UIDevice.current.name
    
    var body: some View {
        VStack{
            Spacer()
                .frame(width: fullScreenSize.width, height: 100, alignment: .top)
            //FieldView().environmentObject(field)
            if battle.wordleState == WordleState.waiting {
                Spacer()
                Button("開始列隊"){
                    battle.connect()
                }.buttonStyle(MainButton())
                    .padding()
                    .padding(.vertical , between.height)
            } else if battle.wordleState == WordleState.Prepare {
                Spacer()
                
                HStack{
                    Spacer()
                    ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white } // Optional configurations (🎁 bouns)
                    Text("\(battle.userCount)名玩家正在等候對戰")
                        .foregroundColor(labelColor)
                    Spacer()
                    
                }
                
                Button("申請對戰"){
                    battle.startWordle(){status in
                        print(status)
                        if status == true{
                            
                        }
                    }
                }.buttonStyle(MainButton())
                    .padding()
                    .padding(.vertical , between.height)
            } else if battle.wordleState == WordleState.Start{
                HStack{
                    
                    Button("上一個"){
                        userFieldId = self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(userFieldId)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        userFieldId = self.battle.nextCompetitor()
                        
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                }
                FieldView().environmentObject(field)
                Spacer()
                Text("已進行：\(String(format: "%02d:%02d", arguments: [battle.mins, battle.secs]))")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
                Button("開啟連結") {
                    showWebView.toggle()
                }.buttonStyle(SecondaryButton())
                    .padding()
                    .sheet(isPresented: $showWebView) {
                        webViewModel.wordleWebview
                    }
            } else if battle.wordleState == WordleState.Submit {
                HStack{
                    
                    Button("上一個"){
                        userFieldId = self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(userFieldId)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        userFieldId = self.battle.nextCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                }
                FieldView().environmentObject(field)
                Spacer()
                
                Text("已進行：\(String(format: "%02d:%02d", arguments: [battle.mins, battle.secs]))")
                    .foregroundColor(.white)
                    .bold()
                Text("您的花費時間：\(battle.submitTime)")
                    .foregroundColor(.white)
                    .bold()
                Text("解答：\(wordleLocalAns)")
                    .foregroundColor(.white)
                    .bold()
                
            } else if battle.wordleState == WordleState.End {
                Spacer()
                Text("比賽結束！")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
                    .padding()
                Text("所有參賽者 / 時間")
                    .foregroundColor(labelColor)
                ForEach(0..<battle.result.count){idx in
                    Text("\(battle.result[idx]["name"].description) : \(battle.result[idx]["time"].description)")
                        .foregroundColor(labelColor)
                }
                Button("開啟連結") {
                    showWebView.toggle()
                }.buttonStyle(SecondaryButton())
                    .padding()
                    .sheet(isPresented: $showWebView) {
                        webViewModel.wordleWebview
                    }
                Spacer()
                
            }
            
        }//.frame(maxWidth: .infinity, maxHeight: fullViewSize.height)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.top)
        .onChange(of: battle.competitorIdx){_ in
            self.updateField()
        }
        .onChange(of: battle.wordleState){newValue in
            if newValue == WordleState.Start{
                self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true){_ in
                    self.updateField()
                }
                showWebView.toggle()
                webViewModel.wordleWebview
            }
        }
    }
    func updateField(){
        for i in 0...field.squareArray.count-1{
            field.squareArray[i].color = .white
        }
        //key is each user id
        let val: JSON = self.battle.evaluations[battleNameToId[self.battle.nowCompetitor()] ?? ""] ?? JSON(NSNull())
        print(self.battle.nowCompetitor(), val)
        let allRounds = JSON(val["evaluations"].arrayValue[0] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
        let allRoundsText = JSON(val["evaluations"].arrayValue[1] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())

        let allRoundsTextArr = allRoundsText.arrayValue

        print(allRounds.arrayValue, allRoundsText)
        
        
        var count = 0
        for round in allRounds.arrayValue{
            var str = allRoundsTextArr[count].description.uppercased()
            print("str", str)
            if round == JSON(NSNull()){
                return
            }
            let result = round.arrayValue.map{ ele -> Color in
                var color = Color.gray
                if ele.stringValue == "present" {
                    color = .yellow
                }else if ele.stringValue == "correct"{
                    color = .green
                }
                return color
            }
            print(result, field.squareArray.count)
            for i in 0...4{
                field.squareArray[count*5 + i].color = result[i]
                if self.battle.wordleState == WordleState.Submit{
                    field.squareArray[count*5 + i].char = String(str.removeFirst())
                }
            }
            count += 1
        }
    }
    func initConnect(){
        print(battle)
    }
    
}

struct BopomofoView: View {
    @State private var showWebView = false
    @EnvironmentObject var battle : BopomofoBattleModel
    var isShowing: Bool = true
    
    @State private var competitors: [JSON] = []
    
    @State var gameStatus = GameStatus.inProgress
    
    @StateObject private var field = FieldModel()
    @State var timer: Timer? = nil
    
    @State var userFieldId : String = UIDevice.current.name
    var body: some View {
        VStack{
            Spacer()
                .frame(width: fullScreenSize.width, height: 100, alignment: .top)

            if battle.bopomofoState == WordleState.waiting {
                Spacer()
                Button("開始列隊"){
                    battle.connect()
                }.buttonStyle(MainButton())
                    .padding()
                    .padding(.vertical , between.height)
            } else if battle.bopomofoState == WordleState.Prepare {
                Spacer()

                HStack{
                    Spacer()
                    ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white } // Optional configurations (🎁 bouns)
                    Text("\(battle.userCount)名玩家正在等候對戰")
                        .foregroundColor(labelColor)
                    Spacer()
                    
                }
                
                Button("申請對戰"){
                    battle.startBopomofo(){status in
                        print(status)
                        if status == true{
                            
                        }
                    }
                }.buttonStyle(MainButton())
                    .padding()
                    .padding(.vertical , between.height)
            } else if battle.bopomofoState == WordleState.Start{
                HStack{
                    
                    Button("上一個"){
                        userFieldId = self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(userFieldId)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        userFieldId = self.battle.nextCompetitor()
                        
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                }
                FieldView().environmentObject(field)
                Spacer()

                Text("已進行：\(String(format: "%02d:%02d", arguments: [battle.mins, battle.secs]))")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
                Button("開啟連結") {
                    showWebView.toggle()
                }.buttonStyle(SecondaryButton())
                    .padding()
                    .sheet(isPresented: $showWebView) {
                        battle.webview
                    }
            } else if battle.bopomofoState == WordleState.Submit {
                HStack{
                    
                    Button("上一個"){
                        userFieldId = self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(userFieldId)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        userFieldId = self.battle.nextCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                }
                FieldView().environmentObject(field)
                Spacer()
                
                Text("已進行：\(String(format: "%02d:%02d", arguments: [battle.mins, battle.secs]))")
                    .foregroundColor(.white)
                    .bold()
                Text("您的花費時間：\(battle.submitTime)")
                    .foregroundColor(.white)
                    .bold()
                Text("解答：\(bopomofoLocalAns)")
                    .foregroundColor(.white)
                    .bold()
            } else if battle.bopomofoState == WordleState.End {
                Spacer()
                Text("比賽結束！")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
                    .padding()
                Text("所有參賽者 / 時間")
                    .foregroundColor(labelColor)
                ForEach(0..<battle.result.count){idx in
                    Text("\(battle.result[idx]["name"].description) : \(battle.result[idx]["time"].description)")
                        .foregroundColor(labelColor)
                }
                Button("開啟連結") {
                    showWebView.toggle()
                }.buttonStyle(SecondaryButton())
                    .padding()
                    .sheet(isPresented: $showWebView) {
                        battle.webview
                    }
                Spacer()
                
            }
            
        }//.frame(maxWidth: .infinity, maxHeight: fullViewSize.height)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.top)
        .onChange(of: battle.competitorIdx){_ in
            self.updateField()
        }
        .onChange(of: battle.bopomofoState){newValue in
            if newValue == WordleState.Start{
                self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true){_ in
                    self.updateField()
                }
                showWebView.toggle()
                webViewModel.bopomofoWebview
                
            }
        }
        //Spacer()
        
    }
    func updateField(){
        for i in 0...field.squareArray.count-1{
            field.squareArray[i].color = .white
        }
        //key is each user id
        let val: JSON = self.battle.evaluations[battleNameToId[self.battle.nowCompetitor()] ?? ""] ?? JSON(NSNull())
        print(self.battle.nowCompetitor(), val)
        let allRounds = JSON(val["evaluations"].arrayValue[0] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
        let allRoundsText = JSON(val["evaluations"].arrayValue[1] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())

        let allRoundsTextArr = allRoundsText.arrayValue

        print(allRounds.arrayValue, allRoundsText)
        
        
        var count = 0
        for round in allRounds.arrayValue{
            var str = String(allRoundsTextArr[count].description)
            print("str", str)
            if round == JSON(NSNull()){
                return
            }
            let result = round.arrayValue.map{ ele -> Color in
                var color = Color.gray
                if ele.stringValue == "present" {
                    color = .yellow
                }else if ele.stringValue == "correct"{
                    color = .green
                }
                return color
            }
            print(result, field.squareArray.count)
            for i in 0...4{
                field.squareArray[count*5 + i].color = result[i]
                if self.battle.bopomofoState == WordleState.Submit{
                    field.squareArray[count*5 + i].char = String(str.removeFirst())
                }
            }
            count += 1
        }
    }
    func initConnect(){
        print(battle)
    }
}

