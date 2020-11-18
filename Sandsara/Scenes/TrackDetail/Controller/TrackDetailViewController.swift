//
//  TrackDetailViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxCocoa
import RxSwift
import Kingfisher
import LNPopupController

class TrackDetailViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var addToPlaylistBtn: UIButton!
    @IBOutlet weak var favBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    
    var track: DisplayItem?
    var selecledIndex = 0
    var tracks = [DisplayItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let track = track else { return }
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
        let player = self.storyboard?.instantiateViewController(withIdentifier: PlayerViewController.identifier) as! PlayerViewController
        player.modalPresentationStyle = .fullScreen
        player.selecledIndex.accept(self.selecledIndex)
        player.tracks = self.tracks
        player.popupContentView.popupCloseButtonStyle = .none

        let customBar = self.storyboard?.instantiateViewController(withIdentifier: PlayerBarViewController.identifier) as! PlayerBarViewController
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            customBar.state = delegate.connectedPeperial == nil ? .noConnect : .connected
        }

        tabBarController?.popupBar.customBarViewController = customBar
        tabBarController?.presentPopupBar(withContentViewController: player, animated: true, completion: nil)

    }

}
