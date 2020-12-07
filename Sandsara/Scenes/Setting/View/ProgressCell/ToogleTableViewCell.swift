//
//  ToogleTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 05/12/2020.
//

import UIKit

class ToogleTableViewCell: BaseTableViewCell<ToogleCellViewModel> {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toogleSwitch: ToggleSwitch!
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        let images = ToggleSwitchImages(baseOnImage: Asset.toggleBaseOn.image,
                                        baseOffImage: Asset.toggleBaseOff.image,
                                        thumbOnImage: Asset.thumbs.image,
                                        thumbOffImage: Asset.thumbs.image)

        toogleSwitch.configurationImages = images
    }

    override func bindViewModel() {
        viewModel.outputs.toogle.drive(toogleSwitch.rx.isOn).disposed(by: disposeBag)
        viewModel.outputs.title.drive(titleLabel.rx.text).disposed(by: disposeBag)

        toogleSwitch.stateChanged = { [weak self] state in
            self?.viewModel.inputs.toogle.accept(state)
        }
    }
}
