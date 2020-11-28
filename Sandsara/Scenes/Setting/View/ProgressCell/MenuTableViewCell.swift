//
//  MenuTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit

class MenuTableViewCell: BaseTableViewCell<MenuCellViewModel> {

    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        selectionStyle = .none
        titleLabel.font = FontFamily.OpenSans.regular.font(size: 18)
    }

    override func bindViewModel() {
        titleLabel.textColor = viewModel.inputs.color
        viewModel
            .outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
