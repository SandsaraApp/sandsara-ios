//
//  ScanDevicesViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit
import RxSwift
import RxCocoa

class ScanDevicesViewController: BaseVMViewController<ScanDevicesViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var rightButton: UIBarButtonItem!

    var dataSource: TableViewDataSource<ScanResultsViewModelItem>?

    private var scanButtonTrigger = PublishRelay<()>()
    private var stopScanButtonTrigger = PublishRelay<()>()
    private var isScanning = BehaviorRelay<Bool>(value: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setDataSourceRefreshBlock()
    }

    private func setupTableView() {
        tableView.register(DeviceTableViewCell.nib, forCellReuseIdentifier: DeviceTableViewCell.identifier)
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    private func setDataSourceRefreshBlock() {
        self.dataSource?.setRefreshBlock { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func setupViewModel() {
        let dataItem = ScanResultsViewModelItem("Results")
        dataSource = TableViewDataSource<ScanResultsViewModelItem>(dataItem: dataItem)

        let vmInput = ScanDevicesViewModelContract.Input(scanAction: scanButtonTrigger,
                                                         stopAction: stopScanButtonTrigger)

        viewModel = ScanDevicesViewModel(inputs: vmInput, service: RxBluetoothKitService())
    }

    override func bindViewModel() {
        dataSource?.bindItemsObserver(to: viewModel.outputs.scanningOutput)

        isScanning
            .asDriver()
            .driveNext { [weak self] isScanning in
            guard let self = self else { return }
            self.rightButton.title = isScanning ? "Scanning" : "Scan"
        }.disposed(by: disposeBag)

        scanButtonTrigger.subscribeNext { [weak self] in
            self?.dataSource?.bindData()
        }.disposed(by: disposeBag)

        rightButton
            .rx.tap
            .subscribeNext { [weak self] in
                guard let self = self else { return }
                _ = self.isScanning.value ? self.stopScanButtonTrigger.accept(()): self.scanButtonTrigger.accept(())
                self.isScanning.accept(!self.isScanning.value)
            }
            .disposed(by: disposeBag)
    }
}

extension ScanDevicesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let tabBar = storyboard?.instantiateViewController(withIdentifier: "tabbarVC") as? UITabBarController
        delegate.window?.rootViewController = tabBar
    }
}
