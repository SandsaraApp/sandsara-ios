//
//  ProgressTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit
import RxSwift
import RxCocoa


class ProgressTableViewCell: BaseTableViewCell<ProgressCellViewModel> {
    @IBOutlet private weak var progressNameLabel: UILabel!
    @IBOutlet private weak var progressSlider: UISlider!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(progressNameLabel.rx.text)
            .disposed(by: disposeBag)

        progressSlider
            .rx.value
            .bind(to: viewModel.inputs.progress)
            .disposed(by: disposeBag)
    }

}
