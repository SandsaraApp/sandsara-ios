//
//  AdvanceSettingViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 28/11/2020.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

class AdvanceSettingViewController: BaseVMViewController<AdvanceSettingViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, SettingItemCellType>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()


    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar(largeTitleColor: Asset.primary.color, backgoundColor: Asset.background.color, tintColor: Asset.primary.color, title: L10n.advanceSetting, preferredLargeTitle: true)
    }

    override func setupViewModel() {
        setupTableView()
        viewModel = AdvanceSettingViewModel(inputs: AdvanceSettingViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
        viewWillAppearTrigger.accept(())
    }

    override func bindViewModel() {
        viewModel
            .outputs.datasources
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(MenuTableViewCell.nib, forCellReuseIdentifier: MenuTableViewCell.identifier)

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 73

        tableView.register(SettingHeaderView.nib, forHeaderFooterViewReuseIdentifier: SettingHeaderView.identifier)

        Observable
            .zip(
                tableView.rx.itemSelected,
                tableView.rx.modelSelected(SettingItemCellType.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                switch model {
                case .menu(let viewModel):
                    switch viewModel.inputs.type {
                    case .changeName:
                        let alert = UIAlertController(title: nil, message: "Update Name", preferredStyle: .alert)
                        alert.addTextField { (textField) in
                            textField.placeholder = "Enter a new name for Sandsara here"
                        }
                        alert.addAction(UIAlertAction(title: L10n.ok, style: .default, handler: { [weak alert] (_) in
                            if let textField = alert?.textFields?[0]  {
                                if let text = textField.text {
                                    if text.isEmpty == false {
                                        DeviceServiceImpl.shared.updateDeviceName(name: text)
                                        DeviceServiceImpl.shared.updateError.subscribeNext { error in
                                            if error == nil {
                                                DeviceServiceImpl.shared.deviceName.accept(text)
                                                self.showSuccessHUD(message: "Name \(text) was updated successfully")
                                                self.viewWillAppearTrigger.accept(())
                                            } else {
                                                self.showErrorHUD(message: "\(error?.localizedDescription ?? "")")
                                            }
                                        }.disposed(by: self.disposeBag)
                                    }
                                }
                            }}))

                        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    case .factoryReset:
                        viewModel.sendCommand(command: "1")
                    default: break
                    }
                default: break
                }
        }.disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, modelType) -> UITableViewCell in
                switch modelType {
                case .menu(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                default: return UITableViewCell()
                }

            })
    }
}

extension AdvanceSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingHeaderView.identifier) as? SettingHeaderView
        headerView?.titleLabel.text = L10n.about
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 73
    }
}
