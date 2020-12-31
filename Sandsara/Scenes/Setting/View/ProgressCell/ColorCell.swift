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
        gradientView.layer.cornerRadius = gradientView.frame.size.width / 2
        gradientView.clipsToBounds = true
    }



    override func bindViewModel() {
        viewModel
            .outputs
            .color
            .driveNext { color in
                self.gradientView.colors = color.colors.map {
                    UIColor(hexString: $0)
                }
                self.gradientView.locations = color.position.map {
                    CGFloat($0) / 255.0
                }
                self.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientView.layer.cornerRadius = gradientView.frame.size.width / 2
        gradientView.clipsToBounds = true
    }
}
