//
//  BrowseViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 11/8/20.
//

import UIKit
import Alamofire

class BrowseViewController: BaseVMViewController<BrowseViewModel, NoInputParam> {

    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(RecommendTableViewCell.nib,
                               forCellReuseIdentifier: RecommendTableViewCell.identifier)
            tableView.tableFooterView = UIView()
            tableView?.register(HeaderView.nib,
                                forHeaderFooterViewReuseIdentifier: HeaderView.identifier)
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
