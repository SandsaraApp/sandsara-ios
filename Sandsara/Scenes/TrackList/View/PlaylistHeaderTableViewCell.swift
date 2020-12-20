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
    @IBOutlet weak var downloadButton: LoadingButton!

    let backAction = PublishRelay<()>()

    let playAction = PublishRelay<()>()

    let deleteAction = PublishRelay<()>()

    let playlistTrigger = PublishRelay<()>()

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

        checkDownloaed()

        downloadButton
            .rx.tap.asDriver()
            .driveNext {
                let completion = BlockOperation {
                    self.checkDownloaed()
                    self.downloadButton.hideLoading()
                    self.playlistTrigger.accept(())
                }
                let track = self.viewModel.inputs.track
                let name = self.viewModel.inputs.track.fileName; let size = track.fileSize; let urlString = track.fileURL
                guard let url = URL(string: urlString) else { return }
                let resultCheck = FileServiceImpl.shared.existingFile(fileName: name)
                if resultCheck.0 == false || resultCheck.1 < size {
                    let operation = DownloadManager.shared.queueDownload(url, item: track)
                    self.downloadButton.showLoading()
                    completion.addDependency(operation)
                }

                OperationQueue.main.addOperation(completion)
        }.disposed(by: disposeBag)
    }

    func checkDownloaed() {
        let check = DataLayer.loadDownloadedDetail(name: self.viewModel.inputs.track.title)
        DispatchQueue.main.async {
            self.downloadButton.isHidden = check
        }
    }
}
