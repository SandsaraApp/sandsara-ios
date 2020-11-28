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
        viewModel
            .outputs
            .title
            .drive(progressNameLabel.rx.text)
            .disposed(by: disposeBag)

        if viewModel.inputs.type == .lightCycleSpeed {
            progressSlider.maximumValue = 500
            progressSlider.minimumValue = 10
            progressSlider
                .rx.value
                .changed
                .debounce(.milliseconds(400), scheduler: MainScheduler.asyncInstance)
                .compactMap { Int($0) }
                .subscribeNext { value in
                    bluejay.write(to: ledStripSpeed, value: String(format:"%02X", value)) { result in
                        switch result {
                        case .success:
                            debugPrint("Write to sensor location is successful.\(result)")
                        case .failure(let error):
                            debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
                        }
                    }
                }.disposed(by: disposeBag)
        }
    }

}
