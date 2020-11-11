//
//  ToogleTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit

class ToogleTableViewCell: BaseTableViewCell<ToogleCellViewModel> {

    @IBOutlet private weak var toogleSwitch: UISwitch!
    @IBOutlet private weak var toogleNameLabel: UILabel!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(toogleNameLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}
