//
//  AllTrackViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 15/11/2020.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import Moya

class AllTrackViewController: BaseVMViewController<AllTracksViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!

    let viewWillAppearTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, TrackCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    var playlistTitle: String?

    override func setupViewModel() {
        //configureNavigationBar(largeTitleColor: .white, backgoundColor: .black, tintColor: .white, title: playlistTitle ?? "", preferredLargeTitle: true)
        setupTableView()
        viewModel = AllTracksViewModel(apiService: SandsaraAPIService(apiProvider: MoyaProvider<SandsaraAPI>()), inputs: AllTracksViewModelContract.Input(viewWillAppearTrigger: viewWillAppearTrigger))
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
                trackList.tracks = self.viewModel.datas.value.map { $0.inputs.track }
                trackList.selecledIndex = indexPath.row
                self.navigationController?.pushViewController(trackList, animated: true)
            }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        tableView.backgroundColor = Asset.background.color
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath) as? TrackTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                return cell
            })
    }

}

extension AllTrackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
}
