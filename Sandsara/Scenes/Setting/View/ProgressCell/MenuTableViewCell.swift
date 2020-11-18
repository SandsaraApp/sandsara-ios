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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if viewModel.inputs.type == .disconnect {
            bluejay.disconnect(immediate: true)
        }
    }
    
}
