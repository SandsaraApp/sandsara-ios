//
//  TrackListViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class TrackListViewController: BaseVMViewController<TrackListViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    private let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, TrackCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistTitle: String?

    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func setupViewModel() {
        configureNavigationBar(largeTitleColor: .white, backgoundColor: .black, tintColor: .white, title: playlistTitle ?? "", preferredLargeTitle: true)
        setupTableView()
        viewModel = TrackListViewModel(inputs: TrackListViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
        viewWillAppearTrigger.accept(())
    }

    override func bindViewModel() {
        viewModel
            .outputs.datasources
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        Observable
            .zip(
                tableView.rx.itemSelected,
                tableView.rx.modelSelected(TrackCellViewModel.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                let trackList = self.storyboard?.instantiateViewController(withIdentifier: TrackDetailViewController.identifier) as! TrackDetailViewController
                trackList.track = model.inputs.track
                self.navigationController?.pushViewController(trackList, animated: true)
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

}

extension TrackListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}
