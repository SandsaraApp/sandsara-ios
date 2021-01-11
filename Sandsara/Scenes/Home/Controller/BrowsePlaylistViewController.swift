//
//  BrowsePlaylistViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 07/01/2021.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class BrowsePlaylistViewController: BaseVMViewController<PlaylistViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    let viewWillAppearTrigger = PublishRelay<()>()

    var mode: ControllerMode = .search

    typealias Section = SectionModel<String, PlaylistCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()


    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    let searchTrigger = PublishRelay<String>()

    override func setupViewModel() {
        setupTableView()
        viewModel = PlaylistViewModel(apiService: SandsaraDataServices(), inputs: PlaylistViewModelContract.Input(mode: mode, viewWillAppearTrigger: viewWillAppearTrigger, searchTrigger: searchTrigger))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                tableView.rx.modelSelected(PlaylistCellViewModel.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
                let trackList = self.storyboard?
                    .instantiateViewController(withIdentifier: TrackListViewController.identifier) as! TrackListViewController
                trackList.playlistItem = model.inputs.track
                self.navigationController?.pushViewController(trackList, animated: true)
            }.disposed(by: disposeBag)

        viewModel.isLoading
            .drive(loadingActivity.rx.isAnimating)
            .disposed(by: disposeBag)

        tableView.rx.itemDeleted
            .filter { $0.row != 0 && !self.viewModel.isEmpty }
            .subscribeNext { [weak self] indexPath in
                guard let self = self else { return }
                self.viewModel.deletePlaylist(index: indexPath.row)
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.register(PlaylistTableViewCell.nib, forCellReuseIdentifier: PlaylistTableViewCell.identifier)
        tableView.backgroundColor = Asset.background.color
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)

        dataSource.canEditRowAtIndexPath = { (ds, ip) in
            return self.viewModel.canDeletePlaylist(index: ip.row)
        }
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableViewCell.identifier, for: indexPath) as? PlaylistTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

}

extension BrowsePlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
}