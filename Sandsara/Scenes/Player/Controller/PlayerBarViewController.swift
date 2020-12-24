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


enum PlayerState {
    case noConnect
    case connected
    case busy
    case haveTrack(displayItem: DisplayItem?)

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

    @IBOutlet weak var playerContentView: UIView!

    private let disposeBag = DisposeBag()

    var state: PlayerState = .noConnect {
        didSet {
            popupItemDidUpdate()
        }
    }

    @IBOutlet var heightConstraint: NSLayoutConstraint!

    override var wantsDefaultTapGestureRecognizer: Bool {
        return false
    }

    override var wantsDefaultPanGestureRecognizer: Bool {
        return false
    }


    fileprivate func updateConstraint() {
        heightConstraint.constant = 60
        self.preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        connectionTitleLabel.font = FontFamily.OpenSans.bold.font(size: 12)
        retryBtn.titleLabel?.font = FontFamily.OpenSans.regular.font(size: 12)

        songLabel.font = FontFamily.OpenSans.bold.font(size: 12)
        authorLabel.font = FontFamily.OpenSans.light.font(size: 12)

        view.translatesAutoresizingMaskIntoConstraints = false

        updateConstraint()

        retryBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.openScanVC()
        }.disposed(by: disposeBag)

        pauseButton.rx.tap.asDriver().driveNext {
            print("tapped")
        }.disposed(by: disposeBag)

        playerContentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPlayer)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func popupItemDidUpdate() {
        if connectionBar != nil {
            Driver.just(state)
                .driveNext { state in
                    if !state.isConnection {
                        self.view.addGestureRecognizer(self.popupContentView.popupInteractionGestureRecognizer)
                    }
                    switch state {
                    case .busy:
                        self.playerBar.isHidden = true
                        self.connectionBar.isHidden = false
                        self.connectionTitleLabel.text = L10n.syncNoti
                        self.retryBtn.isHidden = true
                    case .connected:
                        self.playerBar.isHidden = true
                        self.connectionBar.isHidden = false
                        self.connectionTitleLabel.text = L10n.sandsaraDetected
                        self.retryBtn.isHidden = false
                    case .noConnect:
                        self.playerBar.isHidden = true
                        self.connectionBar.isHidden = false
                        self.connectionTitleLabel.text = L10n.noSandsaraDetected
                        self.retryBtn.isHidden = false
                    case .haveTrack(let item):
                        self.playerBar.isHidden = false
                        self.connectionBar.isHidden = true
                        self.trackImageView.kf.setImage(with: URL(string: item?.thumbnail ?? ""))
                        self.songLabel.text = item?.title
                        self.authorLabel.text = L10n.authorBy(item?.author ?? "")
                    }
            }.disposed(by: disposeBag)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [unowned self] context in
            updateConstraint()
        }, completion: nil)
    }

    private func openScanVC() {
        let scanVC: ScanViewController = self.storyboard?.instantiateViewController(withIdentifier: ScanViewController.identifier) as! ScanViewController
        let navVC = UINavigationController(rootViewController: scanVC)
        self.present(navVC, animated: true, completion: nil)
    }


    @objc func openPlayer() {
        UIApplication.topViewController()?.tabBarController?.openPopup(animated: true, completion: nil)
    }
}
