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
    @IBOutlet weak var downloadButton: ProgressButtonUIView!
    @IBOutlet weak var syncButton: ProgressButtonUIView!

    let backAction = PublishRelay<()>()

    let playAction = PublishRelay<()>()

    let deleteAction = PublishRelay<()>()

    let playlistTrigger = PublishRelay<()>()

    var state: TrackState = .download {
        didSet {
            trackDetailUIConfig()
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
    }

    override func bindViewModel() {
        downloadButton.setupUI(title: L10n.download,
                               image: Asset.download.image,
                               font: FontFamily.OpenSans.regular.font(size: 18),
                               inProgressTitle: L10n.downloading,
                               color: Asset.primary.color)

        syncButton.setupUI(title: L10n.syncToBoard,
                           image: Asset.sync1.image,
                           font: FontFamily.OpenSans.regular.font(size: 18),
                           inProgressTitle: L10n.syncing,
                           color: Asset.primary.color)

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


        downloadButton.touchEvent = { [weak self] in
            self?.downloadAction()
        }

        syncButton.touchEvent = { [weak self] in
            self?.syncAction()
        }
        checkDownloaed()
    }

    private func downloadAction() {
        let track = viewModel.inputs.track
        let completion = BlockOperation {
            self.checkDownloaed()
            self.playlistTrigger.accept(())
        }
        let name = track.fileName; let size = track.fileSize; let urlString = track.fileURL
        guard let url = URL(string: urlString) else { return }
        let resultCheck = FileServiceImpl.shared.existingFile(fileName: name)
        if resultCheck.0 == false || resultCheck.1 < size {
            let operation = DownloadManager.shared.queueDownload(url, item: track)
            print(operation.progress.value)
            operation
                .progress.bind(to: self.downloadButton.progressBar.rx.progress)
                .disposed(by: operation.disposeBag)
            completion.addDependency(operation)
            OperationQueue.main.addOperation(completion)
        } else {
            _ = DataLayer.createDownloaedPlaylist(playlist: track)
        }
    }

    private func getCurrentSyncTask(item: DisplayItem) {
        if let task = FileSyncManager.shared.findCurrentQueue(item: item) {
            DispatchQueue.main.async {
                self.syncButton.isTaskRunning = true
            }
            task.progress
                .bind(to: self.syncButton.progressBar.rx.progress)
                .disposed(by: task.disposeBag)
        }
    }

    private func syncAction() {
        let track = viewModel.inputs.track
        let completion = BlockOperation {
            self.checkSynced()
        }

        let operation = FileSyncManager.shared.queueDownload(item: track)
        operation.progress
            .bind(to: self.syncButton.progressBar.rx.progress)
            .disposed(by: operation.disposeBag)

        FileSyncManager.shared.triggerOperation(id: track.trackId)

        completion.addDependency(operation)

        OperationQueue.main.addOperation(completion)
    }

    private func checkSynced() {
        let item = viewModel.inputs.track
        guard !item.isLocal else {
            self.state = .synced
            return
        }
        let synced = DataLayer.loadSyncedList(name: item.title)
        DispatchQueue.main.async {
            self.state = synced ? .synced : .downloaded
            if !synced {
                self.getCurrentSyncTask(item: item)
            }
        }
    }

    func checkDownloaed() {
        guard !viewModel.inputs.track.isTestPlaylist && !viewModel.inputs.track.isLocal
        else {
            checkSynced(); return
        }
        let item = viewModel.inputs.track
        let downloaded = DataLayer.loadDownloadedDetail(name: item.title)
        DispatchQueue.main.async {
            self.state = downloaded ? .downloaded : .download
            if self.state == .downloaded {
                self.checkSynced()
            }
        }
    }

    private func trackDetailUIConfig() {
        playBtn.isHidden = (state == .download || state == .downloaded)
        downloadButton.isHidden = state != .download
        syncButton.isHidden = state != .downloaded
    }
}
