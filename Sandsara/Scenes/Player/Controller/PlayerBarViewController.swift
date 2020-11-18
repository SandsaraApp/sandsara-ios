//
//  PlayerBarViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 18/11/2020.
//

import UIKit
import LNPopupController
import RxSwift
import RxCocoa
import Kingfisher

enum PlayerState {
    case noConnect
    case connected
    case haveTrack(displayItem: DisplayItem)

    var isConnection: Bool {
        return self == .connected || self == .noConnect
    }
}

extension PlayerState: Equatable {
    static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        return false
    }
}

class PlayerBarView: UIView {
    override var frame: CGRect {
        didSet {
            print("Size: \(self.frame)")
        }
    }
}


class PlayerBarViewController: LNPopupCustomBarViewController {

    @IBOutlet weak var connectionBar: UIView!
    @IBOutlet weak var playerBar: UIView!
    @IBOutlet weak var connectionTitleLabel: UILabel!
    @IBOutlet weak var retryBtn: UIButton!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!

    private let disposeBag = DisposeBag()

    var state: PlayerState = .noConnect {
        didSet {
            popupItemDidUpdate()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        retryBtn.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.getConnected()
            }
        }.disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) 
    }

    override func popupItemDidUpdate() {
        if connectionBar != nil {
            Driver.just(state)
                .driveNext { state in
                    self.connectionBar.isHidden = !state.isConnection
                    self.playerBar.isHidden = state.isConnection
                    switch state {
                    case .connected:
                        self.connectionTitleLabel.text = L10n.sandsaraDetected
                        self.retryBtn.isHidden = true
                    case .noConnect:
                        self.connectionTitleLabel.text = L10n.noSandsaraDetected
                        self.retryBtn.isHidden = false
                    case .haveTrack(let item):
                        self.trackImageView.kf.setImage(with: URL(string: item.thumbnail))
                        self.songLabel.text = item.title
                        self.authorLabel.text = item.author
                    }
            }.disposed(by: disposeBag)
        }
    }

}
