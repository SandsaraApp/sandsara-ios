//
//  AssetsColor.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit

enum AssetsColor: String {
    case background
    case primary
    case secondary
    case tertiary
}

extension UIColor {
    static func appColor(_ name: AssetsColor) -> UIColor {
        return UIColor(named: name.rawValue) ?? .black
    }
}
