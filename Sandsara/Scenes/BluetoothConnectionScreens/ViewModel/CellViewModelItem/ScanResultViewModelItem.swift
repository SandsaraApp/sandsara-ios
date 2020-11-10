import RxBluetoothKit
import UIKit

final class ScanResultsViewModelItem: SectionModelItem {
    typealias CellType = DeviceTableViewCell

    typealias ModelDataType = ScannedPeripheral

    var rowData: [ModelDataType] {
        return peripheralRowItems
    }

    var itemsCount: Int {
        return peripheralRowItems.count
    }

    var sectionName: String?

    var cellClass: DeviceTableViewCell.Type {
        return DeviceTableViewCell.self
    }

    private(set) var peripheralRowItems: [ModelDataType]

    init(_ sectionName: String, peripheralRowItems: [ModelDataType] = []) {
        self.sectionName = sectionName
        self.peripheralRowItems = peripheralRowItems
    }

    func append(_ item: ModelDataType) {
        let identicalPeripheral = peripheralRowItems.filter {
            $0.peripheral == item.peripheral
        }

        guard identicalPeripheral.isEmpty else {
            return
        }

        guard let name = item.peripheral.name ?? item.advertisementData.localName, !name.isEmpty else {
            return
        }

        peripheralRowItems.append(item)
    }
}
