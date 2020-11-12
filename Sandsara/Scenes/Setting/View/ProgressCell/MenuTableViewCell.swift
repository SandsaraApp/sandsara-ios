//
//  MenuTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit

class MenuTableViewCell: BaseTableViewCell<MenuCellViewModel> {

    @IBOutlet private weak var titleLabel: UILabel!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}
