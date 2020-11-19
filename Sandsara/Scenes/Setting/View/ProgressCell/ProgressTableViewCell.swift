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

        if viewModel.inputs.type == .speed {

            progressSlider.maximumValue = 50
            progressSlider.minimumValue = 10
            progressSlider
                .rx.value
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
        } else {
            progressSlider.maximumValue = 15
            progressSlider.minimumValue = 1
            progressSlider
                .rx.value
                .compactMap { Int($0) }
                .subscribeNext { value in
                    bluejay.write(to: selectPattle, value: String(format:"%02X", value)) { result in
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
