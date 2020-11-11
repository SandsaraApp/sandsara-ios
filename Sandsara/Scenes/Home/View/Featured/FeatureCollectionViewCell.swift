//
//  FeatureCollectionViewCell.swift
//  
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import UIKit
import Kingfisher

class FeatureCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var genreImageView: UIImageView!
    @IBOutlet weak var genreTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func bind(_ genre: GenreItem) {
        genreTitleLabel.text = genre.title
        if let url = URL(string: genre.thumbnail) {
            genreImageView.kf.setImage(with: url)
        }
    }
}
