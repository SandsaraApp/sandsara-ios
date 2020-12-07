//
//  ColorCell.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit

class ColorCell: BaseCollectionViewCell<PresetCellViewModel> {

    @IBOutlet weak var gradientView: GradientView!

    override func awakeFromNib() {
        super.awakeFromNib()
        gradientView.mode = .linear
        gradientView.direction = .horizontal
    }

    override func bindViewModel() {
        viewModel
            .outputs
            .color
            .driveNext { color in
                self.gradientView.colors = color.colors
                self.gradientView.locations = color.posistion.map {
                    $0 / 255.0
                }
            }
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        gradientView.layer.cornerRadius = gradientView.frame.size.width / 2
    }
}
