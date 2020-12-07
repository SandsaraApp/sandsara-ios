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

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        progressNameLabel.font = FontFamily.OpenSans.regular.font(size: 18)
        progressNameLabel.textColor = Asset.primary.color

        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            progressSlider.setThumbImage(Asset.thumbs.image, for: state)
        }
    }

    override func bindViewModel() {
        progressSlider.maximumValue = viewModel.inputs.type.sliderValue.1
        progressSlider.minimumValue = viewModel.inputs.type.sliderValue.0

        viewModel
            .outputs
            .title
            .drive(progressNameLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .outputs
            .progress
            .drive(progressSlider.rx.value)
            .disposed(by: disposeBag)

        progressSlider
            .rx.value
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .bind(to: viewModel.inputs.progress).disposed(by: disposeBag)
    }

}
