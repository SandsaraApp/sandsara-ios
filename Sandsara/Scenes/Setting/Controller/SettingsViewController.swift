//
//  SettingsViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/11/20.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

class SettingsViewController: BaseVMViewController<SettingViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, SettingItemCellType>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()


    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func setupViewModel() {
        setupTableView()
        viewModel = SettingViewModel(inputs: SettingViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
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

        tableView.register(ProgressTableViewCell.nib, forCellReuseIdentifier: ProgressTableViewCell.identifier)
        tableView.register(ToogleTableViewCell.nib, forCellReuseIdentifier: ToogleTableViewCell.identifier)
        tableView.register(MenuTableViewCell.nib, forCellReuseIdentifier: MenuTableViewCell.identifier)
        tableView.register(TwoTableViewCell.nib, forCellReuseIdentifier: TwoTableViewCell.identifier)

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] (_, tableView, indexPath, modelType) -> UITableViewCell in
                guard let self = self else { return UITableViewCell() }
                switch modelType {
                case .speed(let viewModel), .brightness(let viewModel), .lightTemp(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableViewCell.identifier, for: indexPath) as? ProgressTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .pause(let viewModel), .lightMode(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ToogleTableViewCell.identifier, for: indexPath) as? ToogleTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .colorSettings(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoTableViewCell.identifier, for: indexPath) as? TwoTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                case .draw(let viewModel), .advanced(let viewModel), .visitSandsara(let viewModel), .help(let viewModel), .sleep(let viewModel), .firmwareUpdate(let viewModel), .nightMode(let viewModel), .disconnect(let viewModel):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else { return UITableViewCell()}
                    cell.bind(to: viewModel)
                    return cell
                default: return UITableViewCell()
                }
            })
    }

}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}
