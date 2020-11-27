//
//  SegmentTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit

class SegmentTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentControl: CustomSegmentControl!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
