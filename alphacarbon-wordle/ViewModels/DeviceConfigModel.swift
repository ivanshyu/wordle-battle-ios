//
//  DeviceConfig.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/15.
//

import Foundation
import SwiftUI

let hasNotch = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) > 0
let fixedHeight: CGFloat = hasNotch ? 54 : 22
let viewPaddingSize = CGFloat(16.0) // padding
let fullScreenSize = UIScreen.main.bounds.size
let fullViewSize = CGSize(width: UIScreen.main.bounds.size.width - (CGFloat(viewPaddingSize)*2), height: UIScreen.main.bounds.size.height)
let viewLeftLine = viewPaddingSize
let viewRightLine = fullScreenSize.width - CGFloat(viewPaddingSize)

let gutter = CGSize(width: 16, height: 16)
let between = CGSize(width: 16, height: 32)
let step = CGSize(width: 6, height: 6)
let cornerRadius = 8

let appVersion =  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
