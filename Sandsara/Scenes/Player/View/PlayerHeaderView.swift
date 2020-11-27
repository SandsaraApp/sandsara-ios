//
//  PlayerHeaderView.swift
//  Sandsara
//
//  Created by Tín Phan on 27/11/2020.
//

import UIKit
import RxCocoa
import RxSwift

class PlayerHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var backBtn: UIButton!

    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    static var identifier: String {
        return String(describing: self)
    }

    private let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
    }

    func reloadHeaderCell(trackDisplay: Driver<DisplayItem>) {
        trackDisplay.driveNext { [weak self] track in
            self?.songTitleLabel.text = track.title
            self?.songAuthorLabel.text = L10n.authorBy(track.author)
            self?.trackImageView.kf.setImage(with: URL(string: track.thumbnail))
        }.disposed(by: disposeBag)
    }
}
