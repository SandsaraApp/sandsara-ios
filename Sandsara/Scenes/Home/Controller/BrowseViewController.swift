//
//  BrowseViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import Moya
import RxSwiftExt

class BrowseViewController: BaseVMViewController<BrowseViewModel, NoInputParam> {

    @IBOutlet private weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(RecommendTableViewCell.nib,
                               forCellReuseIdentifier: RecommendTableViewCell.identifier)
            tableView.backgroundColor = Asset.background.color
            tableView
                .rx.setDelegate(self)
                .disposed(by: disposeBag)
        }
    }

   // @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private let sc = UISearchController(searchResultsController: nil)
    private var viewWillAppearTrigger = PublishRelay<()>()
    private var inputTrigger = BehaviorRelay<String?>(value: nil)
    private var cancelSearchTrigger = PublishRelay<()>()

    typealias Section = SectionModel<String, RecommendTableViewCellViewModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    private lazy var dataSource: DataSource = self.makeDataSource()

    private var cellHeightsDictionary: [IndexPath: CGFloat] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearTrigger.accept(())
    }

    override func setupViewModel() {
        sc.searchBar
            .rx
            .text
            .orEmpty.doOnNext{ text in
                if text.isEmpty {
                    self.cancelSearchTrigger.accept(())
                }
            }
            .asObservable()
            .throttle(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: inputTrigger)
            .disposed(by: disposeBag)

        sc.searchBar
            .rx.cancelButtonClicked
            .bind(to: cancelSearchTrigger)
            .disposed(by: disposeBag)

        viewModel = BrowseViewModel(apiService: SandsaraAPIService(apiProvider: MoyaProvider<SandsaraAPI>()),
                                    inputs: BrowseVMContract.Input(searchText: inputTrigger,
                                                                   cancelSearch: cancelSearchTrigger,
                                                                   viewWillAppearTrigger: viewWillAppearTrigger))

        self.viewWillAppearTrigger.accept(())
    }

    override func bindViewModel() {
//        viewModel
//            .isLoading
//            .drive(activityIndicatorView.rx.isAnimating)
//            .disposed(by: disposeBag)

        viewModel
            .outputs
            .datasources
            .map {
                 [Section(model: "", items: $0)]
            }.drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
    }

    private func setUpSearchBar() {
        sc.dimsBackgroundDuringPresentation = false
        searchBarStyle(sc.searchBar)
        navigationItem.searchController = sc
    }

    private func searchBarStyle(_ searchBar: UISearchBar) {
        searchBar.placeholder = "Search"
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = Asset.primary.color
        if let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField,
           let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView {
            glassIconView.image = Asset.smallSearch.image
            glassIconView.image = glassIconView.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            glassIconView.tintColor = Asset.primary.color
            textFieldInsideSearchBar.backgroundColor = UIColor(red: 0.062, green: 0.062, blue: 0.062, alpha: 1)
        }

        extendedLayoutIncludesOpaqueBars = true
        searchBar.tintColor = Asset.primary.color
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func makeDataSource() -> DataSource {
        return RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: RecommendTableViewCell.identifier, for: indexPath) as? RecommendTableViewCell else { return UITableViewCell()}
                cell.bind(to: viewModel)
                cell.selectedCell.subscribeNext { [weak self] index, item in
                    self?.goDetail(item: item, index: index, viewModel: viewModel)
                }.disposed(by: cell.disposeBag)
                return cell
            })
    }

    private func goDetail(item: DisplayItem, index: Int, viewModel: RecommendTableViewCellViewModel) {
        if item.isPlaylist {
            let trackList = self.storyboard?.instantiateViewController(withIdentifier: TrackListViewController.identifier) as! TrackListViewController
            trackList.playlistTitle = item.title
            navigationController?.pushViewController(trackList, animated: true)
        } else {
            let trackDetail = self.storyboard?.instantiateViewController(withIdentifier: TrackDetailViewController.identifier) as! TrackDetailViewController
            trackDetail.track = item
            trackDetail.tracks = viewModel.inputs.items
            trackDetail.selecledIndex = index
            navigationController?.pushViewController(trackDetail, animated: true)
        }
    }
}

extension BrowseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightsDictionary[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightsDictionary[indexPath] ?? UITableView.automaticDimension
    }
}
