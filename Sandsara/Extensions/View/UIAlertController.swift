//
//  UIAlertController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import RxCocoa
import RxSwift

struct ActionSheetItem<Type> {
    let title: String
    let selectType: Type
    let style: UIAlertAction.Style
    let textColor: UIColor
}

extension UIAlertController {
    func addAction<T>(actions: [ActionSheetItem<T>], cancelMessage: String, cancelAction: ((UIAlertAction) -> Void)?) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            actions.map { action ->  UIAlertAction in
                let alertAction = UIAlertAction(title: action.title,
                                                style: action.style) { _ in
                    observer.onNext(action.selectType)
                    observer.onCompleted()
                }
                alertAction.setValue(action.textColor, forKey: "titleTextColor")
                return alertAction
            }.forEach { [weak self] in
                guard let self = self else { return }
                self.addAction($0)
            }

            let cancelAction = UIAlertAction(title: cancelMessage, style: .cancel) {
                cancelAction?($0)
                observer.onCompleted()
            }

            self.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor.white
            self.addAction(cancelAction)

            return Disposables.create { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension UIViewController {
    func showAlert(title: String?,
                   message: String?,
                   preferredStyle: UIAlertController.Style,
                   actions: UIAlertAction...) {
        let alertViewController = UIAlertController(title: title,
                                                    message: message,
                                                    preferredStyle: preferredStyle)
        for action in actions {
            alertViewController.addAction(action)
        }

        present(alertViewController, animated: true, completion: nil)
    }
}

