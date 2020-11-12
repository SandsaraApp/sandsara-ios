//
//  PlayerViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa

class PlayerViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var dismissButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        dismissButton.rx.tap.asDriver().driveNext { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }

}
