//
//  ToogleTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 05/12/2020.
//

import UIKit
import RxSwift
import RxCocoa

class ToogleTableViewCell: BaseTableViewCell<ToogleCellViewModel> {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var toogleSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func bindViewModel() {
        viewModel.outputs.toogle.drive(toogleSwitch.rx.isOn).disposed(by: disposeBag)
        viewModel.outputs.title.drive(titleLabel.rx.text).disposed(by: disposeBag)

        toogleSwitch
            .rx.isOn
            .changed
            .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .asObservable()
            .subscribeNext { [weak self] state in
                self?.viewModel.inputs.toogle.accept(state)
        }.disposed(by: disposeBag)
    }
}
