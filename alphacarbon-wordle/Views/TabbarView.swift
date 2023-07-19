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
    private var connectionMetaData: ConnectionMetaData!
    @ObservedObject var battle: GenericBattleModel
    @ObservedObject var bopomofoBattle: GenericBattleModel
    init(connectionMetaData: ConnectionMetaData){
        self.connectionMetaData = connectionMetaData
        self.battle = GenericBattleModel(connectionOpt: connectionMetaData, type: BattleType.Wordle)
        self.bopomofoBattle = GenericBattleModel(connectionOpt: connectionMetaData, type: BattleType.Bopomofo)

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
            TabbarView(connectionMetaData: ConnectionMetaData(id: "", name: ""))
        }
    }
}

struct WordleView: View {
    @State private var showWebView = false
    @EnvironmentObject var battle : GenericBattleModel
    var isShowing: Bool = true
    
    @State private var competitors: [JSON] = []
    
    @State var gameStatus = GameStatus.inProgress
    
    @StateObject private var field = FieldModel()
    @State var timer: Timer? = nil
    
    @State private var progress = 0.0

    var body: some View {
        VStack{
            Spacer()
                .frame(width: fullScreenSize.width, height: 100, alignment: .top)
            //FieldView().environmentObject(field)
            if battle.state == WordleState.loading {
                Spacer()
                ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white }
                Text("載入中，請稍候")
                    .foregroundColor(labelColor)
                Spacer()
            }
            else if battle.state == WordleState.waiting {
                Spacer()
                Button("開始列隊"){
                    battle.connect()
                }.buttonStyle(MainButton())
                    .padding()
            } else if battle.state == WordleState.Prepare {
                Spacer()
                
                HStack{
                    Spacer()
                    ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white } // Optional configurations (🎁 bouns)
                    Text("\(battle.userCount)名玩家正在等候對戰")
                        .foregroundColor(labelColor)
                    Spacer()
                    
                }
                
                Button("申請對戰"){
                    battle.start(){_ in
                    }
                }.buttonStyle(MainButton())
                    .padding()
            } else if battle.state == WordleState.Start{
                HStack{
                    
                    Button("上一個"){
                        self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(self.battle.nowCompetitor.name)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        self.battle.nextCompetitor()
                        
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
            } else if battle.state == WordleState.Submit {
                HStack{
                    
                    Button("上一個"){
                        self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(self.battle.nowCompetitor.name)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        self.battle.nextCompetitor()
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
                Text("解答：\(wordleAns)")
                    .foregroundColor(.white)
                    .bold()
                
            } else if battle.state == WordleState.End {
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
            Text("版本 " + appVersion)
                .foregroundColor(labelColor)
                .font(.footnote)
            Spacer().frame(width: fullScreenSize.width, height: gutter.height, alignment: .center)
        }//.frame(maxWidth: .infinity, maxHeight: fullViewSize.height)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.top)
        .onChange(of: battle.competitorIdx){_ in
            self.updateField()
        }
        .onChange(of: battle.state){newValue in
            print("detect state changed: ", newValue)
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
        guard let val: JSON = self.battle.evaluations[self.battle.nowCompetitor.id] else {
            return
        }
//        print(self.battle.nowCompetitor, val)
        let allRounds = JSON(val["evaluations"].arrayValue[0] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
        let allRoundsText = JSON(val["evaluations"].arrayValue[1] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())

        let allRoundsTextArr = allRoundsText.arrayValue

//        print(allRounds.arrayValue, allRoundsText)
        
        
        var count = 0
        for round in allRounds.arrayValue{
            var str = allRoundsTextArr[count].description.uppercased()
//            print("str", str)
            if round == JSON(NSNull()){
                return
            }
            let result = round.arrayValue.map{ ele -> Color in
                var color = Color.gray
                if ele.stringValue == "present" {
                    color = .yellow
                }else if ele.stringValue == "correct"{
                    color = .green
                }else if ele.stringValue == "error"{
                    color = .white
                }
                return color
            }
//            print(result, field.squareArray.count)
            for i in 0...4{
                field.squareArray[count*5 + i].color = result[i]
                if self.battle.state == WordleState.Submit && str.count > 0{
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
    @EnvironmentObject var battle : GenericBattleModel
    var isShowing: Bool = true
    
    @State private var competitors: [JSON] = []
    
    @State var gameStatus = GameStatus.inProgress
    
    @StateObject private var field = FieldModel()
    @State var timer: Timer? = nil
    
    var body: some View {
        VStack{
            Spacer()
                .frame(width: fullScreenSize.width, height: 100, alignment: .top)

            if battle.state == WordleState.loading {
                Spacer()
                ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white }
                Text("載入中，請稍候")
                    .foregroundColor(labelColor)
                Spacer()
            }
            else if battle.state == WordleState.waiting {
                Spacer()
                Button("開始列隊"){
                    battle.connect()
                }.buttonStyle(MainButton())
                    .padding()
            } else if battle.state == WordleState.Prepare {
                Spacer()

                HStack{
                    Spacer()
                    ActivityIndicator(isAnimating: isShowing).configure { $0.color = .white } // Optional configurations (🎁 bouns)
                    Text("\(battle.userCount)名玩家正在等候對戰")
                        .foregroundColor(labelColor)
                    Spacer()
                    
                }
                
                Button("申請對戰"){
                    battle.start(){_ in
                    }
                }.buttonStyle(MainButton())
                    .padding()
            } else if battle.state == WordleState.Start{
                HStack{
                    
                    Button("上一個"){
                        self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(self.battle.nowCompetitor.name)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        self.battle.nextCompetitor()
                        
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
                        webViewModel.bopomofoWebview
                    }
            } else if battle.state == WordleState.Submit {
                HStack{
                    
                    Button("上一個"){
                        self.battle.prevCompetitor()
                    }
                    .frame(width: 80, height: 50, alignment: .center)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(self.battle.nowCompetitor.name)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Button("下一個"){
                        self.battle.nextCompetitor()
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
            } else if battle.state == WordleState.End {
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
                        webViewModel.bopomofoWebview
                    }
                Spacer()
                
            }
            Text("版本 " + appVersion)
                .foregroundColor(labelColor)
                .font(.footnote)
            Spacer().frame(width: fullScreenSize.width, height: gutter.height, alignment: .center)
        }//.frame(maxWidth: .infinity, maxHeight: fullViewSize.height)
        .background(primaryColor)
        .edgesIgnoringSafeArea(.top)
        .onChange(of: battle.competitorIdx){_ in
            print("battle.competitorIdx onChange")
            self.updateField()
        }
        .onChange(of: battle.state){newValue in
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
        guard let val: JSON = self.battle.evaluations[self.battle.nowCompetitor.id] else {
            return
        }
        //        print(self.battle.nowCompetitor, val)
        let allRounds = JSON(val["evaluations"].arrayValue[0] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())
        let allRoundsText = JSON(val["evaluations"].arrayValue[1] as Any).description.data(using: String.Encoding.utf8).flatMap({try? JSON(data: $0)}) ?? JSON(NSNull())

        let allRoundsTextArr = allRoundsText.arrayValue

//        print(allRounds.arrayValue, allRoundsText)
        
        
        var count = 0
        for round in allRounds.arrayValue{
            var str = String(allRoundsTextArr[count].description)
//            print("str", str)
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
//            print(result, field.squareArray.count)
            for i in 0...4{
                field.squareArray[count*5 + i].color = result[i]
                if self.battle.state == WordleState.Submit{
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

