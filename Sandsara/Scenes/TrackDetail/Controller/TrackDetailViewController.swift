//
//  TrackDetailViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxCocoa
import RxSwift
import LNPopupController

enum TrackState {
    case download
    case downloaded
    case synced
}

class TrackDetailViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var addToPlaylistBtn: UIButton!
    @IBOutlet weak var favBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var downloadBtn: ProgressButtonUIView!
    @IBOutlet weak var addToQueueBtn: UIButton!
    @IBOutlet weak var sycnButton: UIButton!

    var isFavorite: Bool = false
    
    var track: DisplayItem?
    var selecledIndex = 0
    var tracks = [DisplayItem]()
    var playlistItem: DisplayItem?

    var state: TrackState = .synced {
        didSet {
            trackDetailUIConfig()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIStyle()
        setupUIData()
        buttonAction()
//        checkDownloaed()
        trackDetailUIConfig()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setButtonStyle(button: UIButton?, title: String) {
        button?.titleLabel?.font = FontFamily.OpenSans.regular.font(size: 18)
        button?.setTitle(title, for: .normal)
    }

    private func showPlayer() {
        let player = PlayerViewController.shared
        player.modalPresentationStyle = .fullScreen
        player.tracks = self.tracks
        let index = self.tracks.isEmpty ? 0 : (self.tracks.count > 1 ? self.selecledIndex : 0)
        player.index = index
        player.isReloaded = true
        player.playlistItem = playlistItem
        (tabBarController?.popupBar.customBarViewController as! PlayerBarViewController).state = .haveTrack(displayItem: tracks.isEmpty ? track : tracks[index])
        tabBarController?.popupBar.isHidden = false
        tabBarController?.popupContentView.popupCloseButton.isHidden = true
        tabBarController?.presentPopupBar(withContentViewController: player, openPopup: true, animated: false, completion: nil)
    }

    private func trackDetailUIConfig() {
        addToQueueBtn.isHidden = (state == .download || state == .downloaded)
        playBtn.isHidden = (state == .download || state == .downloaded)
        downloadBtn.isHidden = state != .download
        addToPlaylistBtn.isHidden = state == .download
        favBtn.isHidden = state == .download
        sycnButton.isHidden = state != .downloaded
    }

    private func checkFavorite() {
        if let item = track {
            let localTrack = LocalTrack(track: item)
            isFavorite = DataLayer.loadFavTrack(localTrack)
            DispatchQueue.main.async {
                self.favBtn.setImage(self.isFavorite ? Asset.icons8Heart60.image: Asset.favorite.image, for: .normal)
                self.favBtn.setTitle(self.isFavorite ? L10n.favorited: L10n.favorite, for: .normal)
            }
        }
    }

    private func checkDownloaed() {
        if let item = track {
            let localTrack = LocalTrack(track: item)
            let downloaded = DataLayer.loadDownloadedTrack(localTrack)
            DispatchQueue.main.async {
                self.state = downloaded ? .downloaded : .download
                if self.state == .downloaded {
                    self.checkSynced()
                    self.checkFavorite()
                }
            }
        }
    }

    private func checkSynced() {
        if let item = track {
            let synced = DataLayer.checkTrackIsSynced(item)
            DispatchQueue.main.async {
                self.state = synced ? .synced : .downloaded
            }
        }
    }

    private func updateFavoriteTrack() {
        guard let item = track else { return }
        let localTrack = LocalTrack(track: item)
        if !isFavorite {
            _ = DataLayer.addTrackToFavoriteList(localTrack)
            showSuccessHUD(message: "Track added to Favorite List")
        } else {
            DataLayer.unLikeTrack(localTrack)
            showSuccessHUD(message: "Track removed from Favorite List")
        }
        checkFavorite()
    }

    private func showAddPlaylist() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: AddPlaylistViewController.identifier) as! AddPlaylistViewController
        vc.item = track
        let navVC = UINavigationController(rootViewController: vc)

        present(navVC, animated: true, completion: nil)
    }

    private func setupUIStyle() {
        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
        setButtonStyle(button: playBtn, title: L10n.play)
        setButtonStyle(button: favBtn, title: L10n.favorite)
        setButtonStyle(button: addToPlaylistBtn, title: L10n.addToPlaylist)
        setButtonStyle(button: sycnButton, title: L10n.syncToBoard)
        setButtonStyle(button: addToQueueBtn, title: L10n.addToQueue)

        downloadBtn.setupUI(title: L10n.download,
                            image: Asset.download.image,
                            font: FontFamily.OpenSans.regular.font(size: 18),
                            inProgressTitle: L10n.downloading,
                            color: Asset.primary.color)
    }

    private func setupUIData() {
        guard let track = track else { return }
        songTitleLabel.text = track.title
        songAuthorLabel.text = L10n.authorBy(track.author)
        trackImageView.kf.setImage(with: URL(string: track.thumbnail))
    }

    private func buttonAction() {
        playBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            self.showPlayer()
        }.disposed(by: disposeBag)

        favBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.updateFavoriteTrack()
        }.disposed(by: disposeBag)

        addToPlaylistBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.showAddPlaylist()
        }.disposed(by: disposeBag)

        backBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)

        addToQueueBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self, let item = self.track else { return }
            PlayerViewController.shared.addToQueue(track: item)
        }.disposed(by: disposeBag)

        sycnButton
            .rx.tap.subscribeNext { [weak self] in
                guard let self = self, let track = self.track else {return }
                self.sycnButton.rotate360Degrees()
                let inputString = track.fileName
                let splits = inputString.components(separatedBy: ".")
                FileServiceImpl.shared.sendFiles(fileName: splits.first ?? "", extensionName: splits.last ?? "")
                FileServiceImpl.shared.sendSuccess.subscribeNext {
                    if $0 {
                        _ = DataLayer.addSyncedTrack(track)
                        self.sycnButton.stopRotation()
                        self.checkSynced()
                    }
                }.disposed(by: self.disposeBag)
            }.disposed(by: disposeBag)

        downloadBtn.touchEvent = { [weak self] in
            self?.downloadAction()
        }
    }

    private func downloadAction() {
        guard let track = track else { return }
        let completion = BlockOperation {
            self.checkDownloaed()
        }
        let name = track.fileName; let size = track.fileSize; let urlString = track.fileURL
        guard let url = URL(string: urlString) else { return }
        let resultCheck = FileServiceImpl.shared.existingFile(fileName: name)
        if resultCheck.0 == false || resultCheck.1 < size {
            let operation = DownloadManager.shared.queueDownload(url, item: track)
            print(operation.progress.value)
            operation
                .progress.bind(to: self.downloadBtn.progressBar.rx.progress)
                .disposed(by: self.disposeBag)
            completion.addDependency(operation)
        }

        OperationQueue.main.addOperation(completion)
    }
}
