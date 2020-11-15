//
//  GenreItemDatasource.swift
//  MiniYoutubePlayer
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import UIKit

protocol GenreDatasourceDelegate: class {
    func selectedGenre(_ item: GenreItem)
}

class GenreDatasource: NSObject {
    var items = [GenreItem]()

    weak var delegate: GenreDatasourceDelegate?

    required init(delegate: GenreDatasourceDelegate) {
        self.delegate = delegate
    }
}

extension GenreDatasource: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        if items.count > 0 {
            self.delegate?.selectedGenre(items[indexPath.item])
        }
    }
}

class FeaturedListDatasource: GenreDatasource {
    private struct Constants {
        static let cellHeight: CGFloat = 180.0
        static let cellWidth: CGFloat = 286.0
    }
}

extension FeaturedListDatasource: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if items.count > 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCollectionViewCell.identifier, for: indexPath) as! FeatureCollectionViewCell
           // cell.bind(items[indexPath.item])
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }
}

class GenreListDatasource: GenreDatasource {
    private struct Constants {
        static let cellHeight: CGFloat = 200.0
        static let cellWidth: CGFloat = 170.0
    }
}

extension GenreListDatasource: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if items.count > 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GenreCollectionViewCell.identifier, for: indexPath) as! GenreCollectionViewCell
          //  cell.bind(items[indexPath.item])
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }
}
