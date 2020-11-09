//
//  HeaderView.swift
//  IWA Test
//
//  Created by tin on 5/14/20.
//  Copyright © 2020 iwa. All rights reserved.
//

import UIKit

protocol HeaderViewDelegate: class {
    func toggleSection(header: HeaderView, section: Int)
}

class HeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!

    var section: Int = 0

    weak var delegate: HeaderViewDelegate?

    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        return String(describing: self)
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeader)))
    }

    @objc private func didTapHeader() {
        delegate?.toggleSection(header: self, section: section)
    }
}
