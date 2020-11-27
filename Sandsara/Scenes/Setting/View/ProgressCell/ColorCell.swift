//
//  ColorCell.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit

class ColorCell: BaseCollectionViewCell<PresetCellViewModel> {

    @IBOutlet weak var genreImageView: UIImageView!

    override func bindViewModel() {
        viewModel
            .outputs
            .image
            .drive(genreImageView.rx.image)
            .disposed(by: disposeBag)
    }
}
