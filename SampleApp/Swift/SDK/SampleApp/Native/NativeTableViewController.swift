//
//  NativeTableViewController.swift
//  SampleApp
//
//  Copyright © 2017年 fluct, Inc. All rights reserved.
//

import UIKit
import FluctSDK

class NativeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 20 == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "native", for: indexPath)
            if let cell = cell as? FSSNativeTableViewCell {
                cell.loadAd(withGroupID: "1000076934", unitID: "1000115021")
            }
            return cell
        }

        let otherCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "other", for: indexPath)
        return otherCell
    }
}