//
//  PlaylistHeaderTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 22/11/2020.
//

import UIKit
import RxSwift
import RxCocoa

class PlaylistHeaderTableViewCell: BaseTableViewCell<PlaylistDetailHeaderViewModel> {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!

    let backAction = PublishRelay<()>()

    let playAction = PublishRelay<()>()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
    }

    override func bindViewModel() {
        viewModel.outputs.title.drive(songTitleLabel.rx.text).disposed(by: disposeBag)
        viewModel.outputs.authorTitle.drive(songAuthorLabel.rx.text).disposed(by: disposeBag)

        playBtn.rx.tap.asDriver().driveNext {
            self.playAction.accept(())
        }.disposed(by: disposeBag)

        backBtn.rx.tap.asDriver().driveNext {
            self.backAction.accept(())
        }.disposed(by: disposeBag)
    }
    
}
