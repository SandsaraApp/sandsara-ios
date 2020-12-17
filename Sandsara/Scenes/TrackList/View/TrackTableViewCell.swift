//
//  TrackTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import Kingfisher

class TrackTableViewCell: BaseTableViewCell<TrackCellViewModel> {

    @IBOutlet private weak var syncBtn: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var authorLabel: UILabel!
    @IBOutlet private weak var trackImageView: UIImageView!
    @IBOutlet private weak var syncBtnTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var syncBtnLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var syncBtnWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = Asset.background.color
        titleLabel.textColor = Asset.primary.color
        authorLabel.textColor = Asset.secondary.color
        titleLabel.font = FontFamily.OpenSans.semibold.font(size: 14)
        authorLabel.font = FontFamily.OpenSans.light.font(size: 10)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if syncBtn.isRotating {
            syncBtn.rotate360Degrees()
        }
    }

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

        trackImageView.kf.indicatorType = .activity
        trackImageView.kf.setImage(with: viewModel.outputs.thumbnailUrl)

        viewModel
            .outputs
            .saved
            .driveNext {
                self.updateConstraints(isSynced: $0)
        }.disposed(by: disposeBag)

        syncBtn
            .rx.tap.subscribeNext {
                self.syncBtn.rotate360Degrees()
                let inputString = self.viewModel.inputs.track.fileName
                let splits = inputString.components(separatedBy: ".")
                var fileSuccess = true
                FileServiceImpl.shared.sendFiles(fileName: splits.first ?? "", extensionName: splits.last ?? "")
                FileServiceImpl.shared.sendSuccess.subscribeNext {
                    if $0 {
                        _ = DataLayer.addSyncedTrack(self.viewModel.inputs.track)
                        self.syncBtn.stopRotation()
                        self.updateConstraints(isSynced: true)
                    }
                    fileSuccess = $0
                }.disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)
    }


    func updateConstraints(isSynced: Bool) {
        syncBtn.alpha = isSynced ? 0 :1
        syncBtn.isHidden = isSynced
        syncBtnTrailingConstraint.constant = isSynced ? 0 : 16
        syncBtnWidthConstraint.constant = isSynced ? 0 : 30
        syncBtnLeadingConstraint.constant = isSynced ? 16 : 10
    }
}
