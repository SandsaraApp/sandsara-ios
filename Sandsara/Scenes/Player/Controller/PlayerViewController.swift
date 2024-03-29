//
//  PlayerViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class PlayerViewController: BaseVMViewController<PlayerViewModel, NoInputParam> {


    static var shared: PlayerViewController = {
        let playerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: PlayerViewController.identifier) as! PlayerViewController
        return playerVC
    }()

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songAuthorLabel: UILabel!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var backBtn: UIButton!

    var selecledIndex = BehaviorRelay<Int>(value: 0)
    var tracks = [DisplayItem]()

    var isReloaded = BehaviorRelay<Bool>(value: false)

    typealias Section = SectionModel<String, TrackCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    override func viewDidLoad() {

        setupTableView()
        songTitleLabel.textColor = Asset.primary.color
        songAuthorLabel.textColor = Asset.secondary.color
        songTitleLabel.font = FontFamily.Tinos.regular.font(size: 30)
        songAuthorLabel.font = FontFamily.OpenSans.regular.font(size: 14)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViewModel()
        bindViewModel()
        viewModel.viewModelDidBind()
    }

    override func setupViewModel() {
        viewModel = PlayerViewModel(inputs: PlayerViewModelContract.Input(selectedIndex: selecledIndex, tracks: tracks, isReloaded: isReloaded))
    }

    override func bindViewModel() {
        viewModel.outputs.datasources.filter { !$0.isEmpty }.map {
            [Section(model: "", items: $0)]
        }.do {
            self.tableView.dataSource = nil
            self.tableView.delegate = nil
        }.drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

        viewModel.outputs.trackDisplay.compactMap { $0 }.driveNext { [weak self] track in
            self?.songTitleLabel.text = track.title
            self?.songAuthorLabel.text = L10n.authorBy(track.author)
            self?.trackImageView.kf.setImage(with: URL(string: track.thumbnail))
        }.disposed(by: disposeBag)

        backBtn.rx.tap.asDriver().driveNext { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        Observable
            .zip(
                tableView.rx.itemSelected,
                tableView.rx.modelSelected(TrackCellViewModel.self)
            ).bind { [weak self] indexPath, model in
                guard let self = self else { return }
                self.selecledIndex.accept(indexPath.row)
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

extension PlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
}


