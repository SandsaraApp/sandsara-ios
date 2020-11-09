//
//  AssetsColor.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit

enum AssetsColor: String {
    case selectedColor
    case unselectedColor
    case deviceTextColor
    case tabBar
}

extension UIColor {
    static func appColor(_ name: AssetsColor) -> UIColor {
        return UIColor(named: name.rawValue) ?? .black
    }
}
