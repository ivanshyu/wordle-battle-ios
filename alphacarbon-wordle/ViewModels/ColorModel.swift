//
//  Clor.swift
//  nccc-swiftui
//
//  Created by 徐胤桓 on 2021/8/15.
//

import Foundation
import SwiftUI

let primaryColor = Color(red: 0.0, green: 72/256.0, blue: 118/256.0)
let secondaryColor = Color(red: 255/256, green: 191/256.0, blue: 71/256.0)

let inputBGColor = Color(red:0, green:61/255, blue:99/255)
let inputHintColor = Color(red:229/255, green:229/255, blue:234/255)

let labelColor: Color = Color(UIColor(red:1, green:1, blue:1, alpha:0.55))

extension UIColor {
    /// The SwiftUI color associated with the receiver.
    var suColor: Color { Color(self) }
}

extension UIImage {
    static func gradientImageWithBounds(bounds: CGRect, colors: [CGColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
