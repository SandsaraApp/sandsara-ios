//
//  TrackDetailViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxCocoa
import RxSwift
//import Kingfisher
import LNPopupController

class TrackDetailViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var addToPlaylistBtn: UIButton!
    @IBOutlet weak var favBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!

    var isFavorite: Bool = false
    
    var track: DisplayItem?
    var selecledIndex = 0
    var tracks = [DisplayItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let track = track else { return }

        checkFavorite()
        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songTitleLabel.text = track.title
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
        songAuthorLabel.text = L10n.authorBy(track.author)
        trackImageView.kf.setImage(with: URL(string: track.thumbnail))

        setButtonStyle(button: playBtn, title: L10n.play)
        setButtonStyle(button: favBtn, title: L10n.favorite)
        setButtonStyle(button: addToPlaylistBtn, title: L10n.addToPlaylist)

        playBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            self.showPlayer()
        }.disposed(by: disposeBag)

        favBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.updateFavoriteTrack()
        }.disposed(by: disposeBag)

        addToPlaylistBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.showAddPlaylist()
        }

        backBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
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
        player.selecledIndex.accept(self.selecledIndex)
        player.tracks = self.tracks
        player.isReloaded = true
        (tabBarController?.popupBar.customBarViewController as! PlayerBarViewController).state = .haveTrack(displayItem: self.tracks[self.selecledIndex])
        tabBarController?.popupBar.isHidden = false
        tabBarController?.popupContentView.popupCloseButton.isHidden = true
        tabBarController?.presentPopupBar(withContentViewController: player, openPopup: true, animated: false, completion: nil)
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
}
