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

            appearance.backgroundColor = Asset.background.color
            appearance.shadowImage = UIImage()
            appearance.shadowColor = .white

            appearance.stackedLayoutAppearance.normal.iconColor = Asset.secondary.color
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Asset.secondary.color]
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = Asset.secondary.color

            appearance.stackedLayoutAppearance.selected.iconColor = Asset.primary.color
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Asset.primary.color]

            UITabBar.appearance().standardAppearance = appearance
        } else {
            UITabBarItem.appearance()
                .setTitleTextAttributes(
                    [NSAttributedString.Key.foregroundColor: Asset.primary.color], for: .selected)
            UITabBarItem.appearance()
                .setTitleTextAttributes(
                    [NSAttributedString.Key.foregroundColor: Asset.secondary.color], for: .normal)
            UITabBar.appearance().tintColor = Asset.primary.color
            UITabBar.appearance().backgroundColor =  Asset.background.color
        }
    }

    private static func setNavApperrance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes
            .updateValue(Asset.primary.color, forKey: NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue))
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().prefersLargeTitles = false
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            //   navBarAppearance.configureWithDefaultBackground()
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: Asset.primary.color]
            navBarAppearance.titleTextAttributes = [.foregroundColor: Asset.primary.color]
            navBarAppearance.backgroundColor = Asset.background.color

            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        } else {
            // Fallback on earlier versions
            UINavigationBar.appearance().tintColor = Asset.primary.color
            UINavigationBar.appearance().backgroundColor = Asset.background.color
            UINavigationBar.appearance().barTintColor = Asset.primary.color
        }
    }
}
