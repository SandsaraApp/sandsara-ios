//
//  HeaderView.swift
//  IWA Test
//
//  Created by tin on 5/14/20.
//  Copyright © 2020 iwa. All rights reserved.
//

import UIKit


class SettingHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!


    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        return String(describing: self)
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        let bgView = UIView(frame: self.bounds)
        bgView.backgroundColor = Asset.background.color
        self.insertSubview(bgView, belowSubview: titleLabel)

        titleLabel.font = FontFamily.Tinos.regular.font(size: 25)
        titleLabel.textColor = Asset.primary.color
    }
}
