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
        return self == .connected || self == .busy || self == .noConnect
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
    @IBOutlet weak var subTitleLabel: UILabel!

    @IBOutlet weak var playerContentView: UIView!

    private let disposeBag = DisposeBag()

    var state: PlayerState = .connected {
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
        songLabel.font = FontFamily.OpenSans.bold.font(size: 12)
        authorLabel.font = FontFamily.OpenSans.light.font(size: 12)
        subTitleLabel.font = FontFamily.OpenSans.light.font(size: 12)
        retryBtn.titleLabel?.font = FontFamily.OpenSans.regular.font(size: 12)

        view.translatesAutoresizingMaskIntoConstraints = false

        updateConstraint()

        retryBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.showConnectionVC()
        }.disposed(by: disposeBag)

        retryBtn.sizeToFit()

        pauseButton.rx.tap.asDriver().driveNext { [weak self] in
            guard let self = self else { return }
            if DeviceServiceImpl.shared.status.value == SandsaraStatus.pause || DeviceServiceImpl.shared.status.value == SandsaraStatus.sleep {
                DeviceServiceImpl.shared.resumeDevice()
                PlayerViewController.shared.readProgress()
                self.pauseButton.setImage(Asset.pause.image, for: .normal)
            } else if DeviceServiceImpl.shared.status.value == (SandsaraStatus.running) {
                DeviceServiceImpl.shared.pauseDevice()
                self.pauseButton.setImage(Asset.play.image, for: .normal)
            }
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
                        self.retryBtn.alpha = 0
                    case .connected:
                        self.playerBar.isHidden = true
                        self.connectionBar.isHidden = false
                        DeviceServiceImpl.shared.deviceName
                            .asDriver().drive(self.connectionTitleLabel.rx.text)
                            .disposed(by: self.disposeBag)
                        self.subTitleLabel.text = "Connected"
                        self.retryBtn.isHidden = true
                        self.retryBtn.alpha = 0
                    case .noConnect:
                        self.playerBar.isHidden = true
                        self.connectionBar.isHidden = false
                        self.connectionTitleLabel.text = L10n.noSandsaraDetected
                        self.retryBtn.isHidden = false
                        self.subTitleLabel.text = nil
                        self.retryBtn.alpha = 1
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

    private func showConnectionVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: ConnectionGuideViewController.identifier) as! ConnectionGuideViewController
        let navVC = UINavigationController(rootViewController: vc)
        self.present(navVC, animated: true, completion: nil)
    }


    @objc func openPlayer() {
        UIApplication.topViewController()?.tabBarController?.openPopup(animated: true, completion: nil)
    }
}
