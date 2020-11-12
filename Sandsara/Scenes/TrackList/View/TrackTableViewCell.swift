//
//  TrackTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit

class TrackTableViewCell: BaseTableViewCell<TrackCellViewModel> {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var authorLabel: UILabel!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .outputs
            .authorTitle
            .drive(authorLabel.rx.text)
            .disposed(by: disposeBag)
    }

}
