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
            self.buttonOne.setTitle(values.first, for: .normal)
            self.buttonTwo.setTitle(values.last, for: .normal)
        }.disposed(by: disposeBag)

        buttonOne.rx.tap.asDriver().driveNext {
            let value = Int.random(in: 1..<16)
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
