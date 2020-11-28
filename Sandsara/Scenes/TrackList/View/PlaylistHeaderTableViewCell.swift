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
    @IBOutlet weak var playlistCoverImage: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!

    let backAction = PublishRelay<()>()

    let playAction = PublishRelay<()>()

    let deleteAction = PublishRelay<()>()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
    }

    override func bindViewModel() {
        viewModel
            .outputs
            .isFavoriteList
            .drive(deleteButton.rx.isHidden)
            .disposed(by: disposeBag)
        viewModel
            .outputs
            .title
            .drive(songTitleLabel.rx.text)
            .disposed(by: disposeBag)
        viewModel.outputs.authorTitle.drive(songAuthorLabel.rx.text).disposed(by: disposeBag)

        playBtn.rx.tap.bind(to: playAction).disposed(by: disposeBag)

        backBtn.rx.tap.bind(to: backAction).disposed(by: disposeBag)

        deleteButton.rx.tap.bind(to: deleteAction).disposed(by: disposeBag)

        playlistCoverImage.kf.indicatorType = .activity
        playlistCoverImage.kf.setImage(with: viewModel.outputs.thumbnailUrl)
    }
    
}
