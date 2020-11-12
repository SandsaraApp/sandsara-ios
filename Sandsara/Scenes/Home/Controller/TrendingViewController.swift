//
//  TrendingViewController.swift
//  MiniYoutubePlayer
//
//  Created by tin on 5/13/20.
//  Copyright © 2020 tin. All rights reserved.
//

import UIKit
import Alamofire

class TrendingViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(FeaturedListTableViewCell.nib,
                               forCellReuseIdentifier: FeaturedListTableViewCell.identifier)
            tableView.register(AllGenresTableViewCell.nib,
                               forCellReuseIdentifier: AllGenresTableViewCell.identifier)
            tableView.tableFooterView = UIView()
            tableView?.register(HeaderView.nib,
                                forHeaderFooterViewReuseIdentifier: HeaderView.identifier)
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    lazy var viewModel: TrendingViewModel = {
        [unowned self] in return TrendingViewModel(self)
        }()

    lazy var featuredDatasource: FeaturedListDatasource = {
        [unowned self] in return FeaturedListDatasource(delegate: self)
        }()

    lazy var genresDatasource: GenreListDatasource = {
        [unowned self] in return GenreListDatasource(delegate: self)
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView.startAnimating()
        viewModel.apiCall()

        configureNavigationBar(largeTitleColor: UIColor.appColor(.unselectedColor),
                               backgoundColor: UIColor.appColor(.tabBar),
                               tintColor: UIColor.appColor(.unselectedColor),
                               title: "Home",
                               preferredLargeTitle: true)
    }
}

extension TrendingViewController: TrendingViewModelDelegate {


    func emitLoading(isLoading: Bool) {
        if isLoading {
            tableView.isHidden = true
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.isHidden = false
            self?.tableView.reloadData()
        }
    }

    func showError(error: Error) {

    }

    func showAllGenre(genres: [GenreItem]) {
//        let vc = storyboard?.instantiateViewController(withIdentifier: AllGenresViewController.identifier) as! AllGenresViewController
//        vc.genres = genres
//        vc.hidesBottomBarWhenPushed = true
//        navigationController?.pushViewController(vc, animated: true)
    }


}

extension TrendingViewController: HeaderViewDelegate, GenreDatasourceDelegate {
    func toggleSection(header: HeaderView, section: Int) {
      //  viewModel.playSection(section: section)
    }

    func selectedGenre(_ item: GenreItem) {
        let trackList = storyboard?.instantiateViewController(withIdentifier: TrackListViewController.identifier) as! TrackListViewController
        trackList.playlistTitle = item.title
        self.navigationController?.pushViewController(trackList, animated: true)
    }
}

extension TrendingViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return DiscoverSections.allCases.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.identifier) as? HeaderView
        headerView?.section = section
        headerView?.delegate = self
        headerView?.titleLabel.text = DiscoverSections.allCases[section].title
        return headerView
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DiscoverSections.allCases[section].sectionHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedListTableViewCell.identifier, for: indexPath) as! FeaturedListTableViewCell
            cell.collectionView.dataSource = featuredDatasource
            cell.collectionView.delegate = featuredDatasource
            cell.collectionView.register(FeatureCollectionViewCell.nib, forCellWithReuseIdentifier: FeatureCollectionViewCell.identifier)
            featuredDatasource.items = viewModel.featurePlaylistSection
            cell.collectionView.reloadData()
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: AllGenresTableViewCell.identifier, for: indexPath) as! AllGenresTableViewCell
            cell.collectionView.dataSource = genresDatasource
            cell.collectionView.delegate = genresDatasource
            cell.collectionView.register(GenreCollectionViewCell.nib, forCellWithReuseIdentifier: GenreCollectionViewCell.identifier)
            genresDatasource.items = viewModel.displayGenresSection
            cell.collectionView.reloadData()
            return cell
        default: break
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        if indexPath.section == 0 {
//            viewModel.playTrackOnSection(section: indexPath.section, index: indexPath.row)
//        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
}
