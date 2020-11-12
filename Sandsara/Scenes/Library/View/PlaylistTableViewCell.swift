//
//  PlaylistTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit

class PlaylistTableViewCell: BaseTableViewCell<PlaylistCellViewModel> {

    @IBOutlet private weak var titleLabel: UILabel!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
    }

}
