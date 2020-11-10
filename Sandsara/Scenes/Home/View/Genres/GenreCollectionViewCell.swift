//
//  GenreCollectionViewCell.swift
//
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import UIKit
import Kingfisher

class GenreCollectionViewCell: UICollectionViewCell {

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

    func addBorder() {
        genreImageView.layer.borderColor = #colorLiteral(red: 0.2588235294, green: 0.2588235294, blue: 0.2588235294, alpha: 1)
        genreImageView.layer.borderWidth = 1.0
    }
}
