//
//  ApperanceService.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit

struct AppApperance {

    static func setTheme() {
        setNavApperrance()
        setTabBarAppearance()
    }

    private static func setTabBarAppearance() {
        if #available(iOS 13, *) {
            let appearance = UITabBarAppearance()

            appearance.backgroundColor = .appColor(.background)
            appearance.shadowImage = UIImage()
            appearance.shadowColor = .white

            appearance.stackedLayoutAppearance.normal.iconColor = .appColor(.secondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.appColor(.secondary)]
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .appColor(.secondary)

            appearance.stackedLayoutAppearance.selected.iconColor = .appColor(.primary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.appColor(.primary)]

            UITabBar.appearance().standardAppearance = appearance
        } else {
            UITabBarItem.appearance()
                .setTitleTextAttributes(
                    [NSAttributedString.Key.foregroundColor: UIColor.appColor(.primary)], for: .selected)
            UITabBarItem.appearance()
                .setTitleTextAttributes(
                    [NSAttributedString.Key.foregroundColor: UIColor.appColor(.secondary)], for: .normal)
            UITabBar.appearance().tintColor = UIColor.appColor(.primary)
            UITabBar.appearance().backgroundColor =  UIColor.appColor(.background)
        }
    }

    private static func setNavApperrance() {
        UINavigationBar.appearance().isTranslucent = true
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            //   navBarAppearance.configureWithDefaultBackground()
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.appColor(.primary)]
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.appColor(.primary)]
            navBarAppearance.backgroundColor = UIColor.appColor(.background)

            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        } else {
            // Fallback on earlier versions
            UINavigationBar.appearance().tintColor = .appColor(.primary)
            UINavigationBar.appearance().backgroundColor = .appColor(.background)
            UINavigationBar.appearance().barTintColor = .appColor(.background)
        }
    }
}
