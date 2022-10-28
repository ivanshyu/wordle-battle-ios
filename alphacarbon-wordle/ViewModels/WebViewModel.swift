//
//  WebViewModel.swift
//  alphacarbon-wordle
//
//  Created by 徐胤桓 on 2022/8/10.
//

import Foundation
class WebViewModel: ObservableObject{
    @Published var wordleWebview = WebView(web: nil, url: URL(string: wordle.link)!)
    @Published var bopomofoWebview = WebView(web: nil, url: URL(string: bopomofo.link)!)
}
var webViewModel = WebViewModel()
