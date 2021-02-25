//
//  AboutViewController.swift
//  NerdSummit
//
//  Created by Louis Franco on 2/27/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit
import SafariServices

class AboutViewController: UIViewController {

    @IBOutlet var stackView: UIStackView!

    var sponsors: Sponsors = Sponsors.sharedInstance

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "About us"
        self.sponsors.update { [weak self] (items) in
            DispatchQueue.main.async {
                self?.updateSponsors(items: items)
            }

        }
    }

    func updateSponsors(items: [SponsorsAtLevel]) {
        for (i, level) in items.enumerated() {
            stackView.addArrangedSubview(makeLevelView(level: level.level, color: colors[i % colors.count]))
            for sponsor in level.sponsors {
                let v = makeSponsorView(from: sponsor)
                stackView.addArrangedSubview(v)
            }
        }
    }
    let colors = [
        #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1),
        #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
        #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1),
        #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),
        #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1),
        #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
        #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),
        #colorLiteral(red: 0.4750122428, green: 0.01646117866, blue: 0, alpha: 1),
        #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1),
        #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1),
        #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1),
        #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1),

    ]

    func makeLevelView(level: String, color: UIColor) -> UIView {
        let l = UILabel(frame: .zero)
        l.text = level
        l.backgroundColor = color
        l.textAlignment = .center
        l.font = UIFont.boldSystemFont(ofSize: 36)
        l.textColor = .white

        return l
    }

    func makeSponsorView(from sponsor: Sponsor) -> UIView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        guard let url = URL(string: sponsor.logo) else {
            return iv
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                return
            }
            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode < 400,
                let imageData = data
            else {
                return
            }
            DispatchQueue.main.async { [weak iv] in
                guard let iv = iv else { return }
                iv.image = UIImage(data: imageData)
                iv.setNeedsLayout()
            }

        }
        task.resume()
        return iv
    }

}
