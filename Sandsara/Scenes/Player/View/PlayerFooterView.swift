//
//  PlayerFooterView.swift
//  Sandsara
//
//  Created by Tín Phan on 20/12/2020.
//

import UIKit
import RxSwift

class PlayerFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var trackProgressSlider: UISlider!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!

    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView(color: Asset.background.color)

        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            trackProgressSlider.setThumbImage(Asset.thumbs.image, for: state)
        }
    }
}
