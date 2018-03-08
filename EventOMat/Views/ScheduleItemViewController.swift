//
//  ScheduleItemViewController.swift
//  EventOMat
//
//  Created by Louis Franco on 2/26/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit
import WebKit

class ScheduleItemViewController: UIViewController {

    let webView = WKWebView()

    // This needs to be set in prepareForSegue of the presenter
    var item: ScheduleItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        super.view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: super.topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: super.bottomLayoutGuide.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: super.view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: super.view.trailingAnchor).isActive = true


        self.title = "\(item.room) @ \(item.startTime):00"

        webView.scrollView.isScrollEnabled = true
        let style = "<style>body { font-size: 30pt; margin: 0 20px 0 20px; }</style>"
        let html = "<html><head>\(style)</head><body><h1>\(item.session)</h1>\(item.sessionText)</body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }



}
