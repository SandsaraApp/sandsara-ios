//
//  CellIdentifier.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit

extension UITableViewCell {
    /// Returns the String describing self.
    static var identifier: String { return String(describing: self) }
    /// Returns the UINib with nibName matching the cell's identifier.
    static var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
}

extension UICollectionViewCell {
    /// Returns the String describing self.
    static var identifier: String { return String(describing: self) }
    /// Returns the UINib with nibName matching the cell's identifier.
    static var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
}


@IBDesignable extension UITableViewCell {
    @IBInspectable var selectedColor: UIColor? {
        get { return selectedBackgroundView?.backgroundColor }
        set {
            if let color = newValue {
                selectedBackgroundView = UIView()
                selectedBackgroundView?.backgroundColor = color
            } else {
                selectedBackgroundView = nil
            }
        }
    }
}
