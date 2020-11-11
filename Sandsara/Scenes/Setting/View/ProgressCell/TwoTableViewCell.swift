//
//  TwoTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit

class TwoTableViewCell: BaseTableViewCell<ColorSettingsCellViewModel> {

    @IBOutlet private weak var titleTextLabel: UILabel!
    @IBOutlet private weak var buttonOne: UIButton!
    @IBOutlet private weak var buttonTwo: UIButton!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(titleTextLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.outputs.buttonTitles.driveNext { values in
            buttonOne.setTitle(values.first, for: .normal)
            buttonTwo.setTitle(values.last, for: .normal)
        }.disposed(by: disposeBag)
    }
    
}
