//
//  LocationViewController.swift
//  NerdSummit
//
//  Created by Louis Franco on 2/17/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit

class LocationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Location"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    func showDirectionsInAppleMaps() {
        guard let url = URL(string: "http://maps.apple.com/?daddr=42.3925089,-72.5249694") else { return }
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

    @IBAction func tapDirections(sender: UIButton) {
        showDirectionsInAppleMaps()
    }

    @IBAction func tapMap(sender: UITapGestureRecognizer) {
        showDirectionsInAppleMaps()
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
