//
//  HeaderView.swift
//
//
//  Created by tin on 5/14/20.
//  Copyright © 2020 iwa. All rights reserved.
//

import UIKit

class HeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var backButtton: UIButton!
    @IBOutlet weak var playButton: UIButton!

    var section: Int = 0

    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        return String(describing: self)
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}
