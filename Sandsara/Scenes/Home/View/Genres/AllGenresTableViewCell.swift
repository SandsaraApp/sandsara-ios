//
//  AllGenresTableViewCell.swift
//  MiniYoutubePlayer
//
//  Created by tin on 5/18/20.
//  Copyright © 2020 tin. All rights reserved.
//

import UIKit

class AllGenresTableViewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}
