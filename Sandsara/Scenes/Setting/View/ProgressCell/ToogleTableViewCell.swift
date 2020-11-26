//
//  ToogleTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit

class ToogleTableViewCell: BaseTableViewCell<ToogleCellViewModel> {

    @IBOutlet private weak var toogleSwitch: UISwitch!
    @IBOutlet private weak var toogleNameLabel: UILabel!

    override func bindViewModel() {
        viewModel
            .outputs
            .title
            .drive(toogleNameLabel.rx.text)
            .disposed(by: disposeBag)

//        if viewModel.inputs.type == .lightMode {
////            toogleSwitch.rx.value.compactMap { $0.hashValue }.subscribeNext { value in
////                bluejay.write(to: ledStripCycleEnable, value: String(format:"%02X", value)) { result in
////                    switch result {
////                    case .success:
////                        debugPrint("Write to sensor location is successful.\(result)")
////                    case .failure(let error):
////                        debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
////                    } 
////                }
////            }.disposed(by: disposeBag)
//        } else {
//            toogleSwitch.rx.value.compactMap { $0.hashValue }.subscribeNext { value in
//                bluejay.write(to: ledStripDirection, value: String(format:"%02X", value)) { result in
//                    switch result {
//                    case .success:
//                        debugPrint("Write to sensor location is successful.\(result)")
//                    case .failure(let error):
//                        debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
//                    }
//                }
//            }.disposed(by: disposeBag)
 //       }
    }
    
}
