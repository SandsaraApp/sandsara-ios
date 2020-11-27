//
//  LibraryViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit
import BetterSegmentedControl
import RxSwift
import RxCocoa

class CustomSegmentControl: BetterSegmentedControl {
    private(set) var segmentSelected = BehaviorRelay<Int>(value: 0)

    func setStyle(font: UIFont?, titles: [String]) {
        segments = LabelSegment.segments(withTitles: titles,
                                         normalFont: font,
                                         normalTextColor: Asset.tertiary.color,
                                         selectedFont: font,
                                         selectedTextColor: Asset.primary.color)
        self.addTarget(self, action: #selector(segmentDidSelected), for: .valueChanged)
    }


    @objc
    private func segmentDidSelected() {
        segmentSelected.accept(index)
    }
}

class LibraryViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var segmentControl: CustomSegmentControl!
    @IBOutlet weak var containerView: UIView!

    private let segmentIndexTrigger = BehaviorRelay<Int>(value: 0)
    private var allTrackVC: AllTrackViewController?
    private var playlistsVC: PlaylistViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        initControllers()
        setupSegment()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupSegment() {
        segmentControl.setStyle(font: FontFamily.Tinos.regular.font(size: 30), titles:  [L10n.tracks, L10n.playlists])

        segmentControl
            .segmentSelected
            .observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] index in
                self?.updateControllersByIndex(i: index)
            }
            .disposed(by: disposeBag)
    }

    private func initControllers() {
        allTrackVC = storyboard?.instantiateViewController(withIdentifier: AllTrackViewController.identifier) as? AllTrackViewController

        playlistsVC = storyboard?.instantiateViewController(withIdentifier: PlaylistViewController.identifier) as? PlaylistViewController

        addChildViewController(controller: allTrackVC!, containerView: containerView, byConstraints: true)

    }

    func updateControllersByIndex(i: Int) {
        self.removeAllChildViewController()
        if i == 0 {
            addChildViewController(controller: allTrackVC!, containerView: containerView, byConstraints: true)
            allTrackVC?.viewWillAppearTrigger.accept(())
        } else {
            addChildViewController(controller: playlistsVC!, containerView: containerView, byConstraints: true)
            playlistsVC?.viewWillAppearTrigger.accept(())
        }
    }

    override func triggerAPIAgain() {
        self.showAlert(title: "Alert", message: "No Internet Connection", preferredStyle: .alert, actions:
                        UIAlertAction(title: "Try Again", style: .default, handler: { _ in
                            if self.segmentControl.segmentSelected.value == 0 {
                                self.allTrackVC?.viewWillAppearTrigger.accept(())
                            } else {
                                self.playlistsVC?.viewWillAppearTrigger.accept(())
                            }
                        }),
                       UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
    }
}
