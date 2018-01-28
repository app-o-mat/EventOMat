//
//  HomeViewController.swift
//  EventOMat
//
//  Created by Louis Franco on 2/11/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit
import SafariServices

class HomeViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var logoHeightConstraint: NSLayoutConstraint!
    
    // These are used by the table data source to configure cells.
    var cells: CellViewable!

    override func viewDidLoad() {
        super.viewDidLoad()

        cells = CellViewable(viewController: self, cells: [[
            .largeText(text: "March 18th - 19th 2017"),
            .navigation(text: "Register", imageName: "icon-tickets", navigate: { [weak self] in
                let ticketSite = SFSafariViewController(url: URL(string: "https://ti.to/nerd/nerd-summit-2017")!)
                self?.present(ticketSite, animated: true, completion: nil)
            }),
            .navigation(text: "Location", imageName: "icon-location", navigate: { [weak self] in
                self?.performSegue(withIdentifier: "Location", sender: self)
            }),
            .navigation(text: "Schedule", imageName: "icon-schedule", navigate: {  [weak self] in
                self?.performSegue(withIdentifier: "Schedule", sender: self)
            }),
            .navigation(text: "About us", imageName: "icon-about", navigate: {  [weak self] in
                self?.performSegue(withIdentifier: "About", sender: self)
            }),]])

        self.tableView.dataSource = cells
        self.tableView.delegate = cells

        setLogoHeight()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

    private func setLogoHeight() {
        if #available(iOS 11, *) {
            logoHeightConstraint.constant = 225 + self.view.safeAreaInsets.top
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        setLogoHeight()
    }

    @IBAction func onTapCredits(_ sender: Any) {
        let credits = SFSafariViewController(url: URL(string: "http://loufranco.com/nerdsummit")!)
        self.present(credits, animated: true, completion: nil)
    }
}
