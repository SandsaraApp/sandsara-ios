//
//  UIViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit

class Once {
    var already: Bool = false

    func run(block: () -> Void) {
        guard !already else { return }

        block()
        already = true
    }
}

extension UIViewController {
    static var identifier: String {
        get {
            return String(describing: self)
        }
    }

    func configureNavigationBar(largeTitleColor: UIColor, backgoundColor: UIColor, tintColor: UIColor, title: String, preferredLargeTitle: Bool) {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
         //   navBarAppearance.configureWithDefaultBackground()
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: largeTitleColor]
            navBarAppearance.titleTextAttributes = [.foregroundColor: largeTitleColor]
            navBarAppearance.backgroundColor = backgoundColor

            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.compactAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance

            navigationController?.navigationBar.prefersLargeTitles = preferredLargeTitle
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.tintColor = tintColor
            navigationItem.title = title

        } else {
            // Fallback on earlier versions
            navigationController?.navigationBar.barTintColor = backgoundColor
            navigationController?.navigationBar.tintColor = tintColor
            navigationController?.navigationBar.isTranslucent = false
            navigationItem.title = title
        }
    }

    func showAlertVC(message: String) {
        let alertVC = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)

        alertVC.addAction(UIAlertAction(title: "Try Again", style: .default, handler: nil))

        present(alertVC, animated: true, completion: nil)
    }
}

extension UIViewController {
    /// Remove specific child View Controller from itself
    ///
    /// - Parameters:
    ///   - controller: ViewController need to be added.
    ///   - containerView: ContainerView contains ViewController's view.
    ///   - byConstraints: Adjust contraint mask to supperview (top, bottom, left, right)
    func addChildViewController(controller: UIViewController, containerView: UIView, byConstraints: Bool = false) {
        containerView.addSubview(controller.view)
        addChild(controller)
        controller.didMove(toParent: self)

        controller.view.frame = containerView.bounds
    }

    /// Remove All child ViewControllers from itself
    func removeAllChildViewController() {
        children.forEach {
            removeChildViewController($0)
        }
    }

    /// Remove specific child View Controller from itself except a specific Tag ViewController's View
    func removeAllChildViewControllerExcept(viewByTag tag: Int?) {
        children.forEach {
            if $0.view.tag != tag {
                removeChildViewController($0)
            }
        }
    }

    /// Remove specific child View Controller from itself
    func removeChildViewController(_ viewController: UIViewController) {
        viewController.didMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

