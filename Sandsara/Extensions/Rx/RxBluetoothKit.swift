//
//  RxBluetoothKit.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import RxBluetoothKit
import CoreBluetooth

extension Characteristic: Hashable {
    // DJB Hashing
    public var hashValue: Int {
        let scalarArray: [UInt32] = []
        return scalarArray.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }

    // A characteristic's properties can provide you information if it responds to a write operation. If it does, it can
    // be either responding to the operation or not. In this implementation it was decided to provide .withResponse if
    // it is the operation can be responded and ignoring .withoutResponse type.
    func determineWriteType() -> CBCharacteristicWriteType? {
        let writeType = self.properties.contains(.write) ? CBCharacteristicWriteType.withResponse :
            self.properties.contains(.writeWithoutResponse) ? CBCharacteristicWriteType.withoutResponse : nil

        return writeType
    }
}

extension Peripheral: Hashable {
    // DJB Hashing
    public var hashValue: Int {
        let scalarArray: [UInt32] = []
        return scalarArray.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}
