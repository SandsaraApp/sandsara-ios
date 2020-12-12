//
//  TrackCountTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 09/12/2020.
//

import UIKit

class TrackCountTableViewCell: BaseTableViewCell<DownloadCellViewModel> {
    @IBOutlet private weak var notSyncedCountLabel: UILabel!
    @IBOutlet private weak var timeRemaingLabel: UILabel!
    @IBOutlet private weak var syncAllBtn: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        syncAllBtn.setTitle(L10n.syncAll, for: .normal)
    }

    override func bindViewModel() {
        syncAllBtn
            .rx.tap
            .bind(to: viewModel.inputs.syncAllTrigger)
            .disposed(by: disposeBag)

        viewModel
            .outputs
            .notSyncedTrack
            .driveNext { [weak self] value in
                guard let self = self else { return }
                self.notSyncedCountLabel.text = L10n.xTrackNeedToBeSynced(value)
            }.disposed(by: disposeBag)

        viewModel
            .outputs
            .timeRemaining
            .driveNext { [weak self] value in
                guard let self = self else { return }
                self.timeRemaingLabel.text = L10n.xMinEsimated(value)
            }.disposed(by: disposeBag)
    }
}
