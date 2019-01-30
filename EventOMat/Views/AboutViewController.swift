//
//  AboutViewController.swift
//  EventOMat
//
//  Created by Louis Franco on 2/27/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit
import SafariServices

struct Sponsor {
    let imageName: String
    let url: URL
}

class AboutViewController: UIViewController {

    @IBOutlet var stackView: UIStackView!

    let sponsors: [Sponsor] = [
    ]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "About us"

        for (index, sponsor) in sponsors.enumerated() {
            let v = makeSponsorView(from: sponsor)
            v.tag = index
            stackView.addArrangedSubview(v)
        }
    }

    func makeSponsorView(from sponsor: Sponsor) -> UIView {
        let iv = UIImageView(image: UIImage(named: sponsor.imageName))
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(AboutViewController.sponsorTapped(sender:)))
        iv.addGestureRecognizer(tap)
        iv.contentMode = .center
        iv.clipsToBounds = true
        return iv
    }

    @objc func sponsorTapped(sender: UITapGestureRecognizer) {
        if let index = sender.view?.tag, index < sponsors.count {
            let sponsorSite = SFSafariViewController(url: sponsors[index].url)
            self.present(sponsorSite, animated: true, completion: nil)
        }
    }

}
