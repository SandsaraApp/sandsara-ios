//
//  BrowseViewModel.swift
//  Sandsara
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

enum DiscoverSections: CaseIterable {
    case recommendedPlaylists
    case recommendedTracks

    var title: String {
        switch self {
        case .recommendedPlaylists:
            return L10n.recommendedPlaylists
        case .recommendedTracks:
            return L10n.recommendedTracks
        }
    }

    var sectionHeight: CGFloat {
        return 54.0
    }
}

enum BrowseVMInput {
    struct Input: InputType {
        let searchText: BehaviorRelay<String?>
        let viewWillAppearTrigger: PublishRelay<()>
    }

    struct Output: OutputType {
        
    }
}
