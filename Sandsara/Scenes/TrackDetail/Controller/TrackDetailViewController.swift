//
//  TrackDetailViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxCocoa
import RxSwift

class TrackDetailViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!

    var track: Track?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let track = track else { return }
        songTitleLabel.text = track.title
        songAuthorLabel.text = track.author

        playBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            let player = self.storyboard?.instantiateViewController(withIdentifier: PlayerViewController.identifier) as! PlayerViewController
            player.modalPresentationStyle = .fullScreen
            self.present(player, animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }


}
