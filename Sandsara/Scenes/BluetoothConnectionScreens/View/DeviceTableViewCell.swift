//
//  DeviceTableViewCell.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit
import RxBluetoothKit

class DeviceTableViewCell: UITableViewCell, UpdatableCell {
    typealias ModelDataType = ScannedPeripheral

    @IBOutlet private weak var deviceNameLabel: UILabel!

    func bind(with item: ScannedPeripheral) {
        deviceNameLabel.text = item.advertisementData.localName ?? item.peripheral.name
    }
}
