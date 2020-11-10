//
//  BaseViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import RxSwift
import RxCocoa
import NVActivityIndicatorView

// MARK: - Input & Ouput for View
protocol InputParamView {}
protocol OutputParamView {}

struct NoInputParam: InputParamView {}
struct NoOutputParam: OutputParamView {}

class BaseViewController<Input: InputParamView>: UIViewController {

    private let _disposeBag = DisposeBag()
    var disposeBag: DisposeBag! {
        return _disposeBag
    }

    lazy var loadingActivity: NVActivityIndicatorView! = {
        let indicatorX = (view.frame.width - 50)/2
        let indicatorY = (view.frame.height - 50)/2
        let centerRect = CGRect(x: indicatorX,
                                y: indicatorY,
                                width: 50,
                                height: 50)
        var  loadingActivity = NVActivityIndicatorView(frame: centerRect,
                                                       type: .ballClipRotatePulse,
                                                       color: .blue,
                                                       padding: nil)
        view.addSubview(loadingActivity)
        view.bringSubviewToFront(loadingActivity)
        return loadingActivity
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /// Setup layout navigation bar item
    private func initBarButtonItem(isRight: Bool, image: UIImage?) -> UIBarButtonItem {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.backgroundColor = .clear
        var selector = #selector(lefttButtonClick)
        if isRight {
            selector = #selector(BaseViewController.rightButtonClick)
        }
        button.addTarget(self, action: selector,
                         for: .touchUpInside)
        button.setImage(image, for: .normal)

        return UIBarButtonItem(customView: button)
    }

    func layoutNavigationBarLeft(image: UIImage?) {
        let leftBarButtonItem = initBarButtonItem(isRight: false, image: image)
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }

    func layoutNavigationBarRight(image: UIImage?) {
        let rightBarButtonItem = initBarButtonItem(isRight: true, image: image)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }

    @objc func rightButtonClick() {}

    @objc func lefttButtonClick() {}
}
