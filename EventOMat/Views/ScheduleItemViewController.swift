//
//  ScheduleItemViewController.swift
//  EventOMat
//
//  Created by Louis Franco on 2/26/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import UIKit
import WebKit

class ScheduleItemViewController: UIViewController, WKNavigationDelegate {

    let config = WKWebViewConfiguration()
    var webView: WKWebView! = nil

    // This needs to be set in prepareForSegue of the presenter
    var item: ScheduleItem!

    override func viewDidLoad() {
        config.dataDetectorTypes = [.link]
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        super.viewDidLoad()

        super.view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: super.topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: super.bottomLayoutGuide.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: super.view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: super.view.trailingAnchor).isActive = true

        let text = item.sessionText

        self.title = "\(item.room) @ \(Schedule.formatTime(time: item.startTime))"

        webView.scrollView.isScrollEnabled = true
        let style = "<style>body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 30pt; margin: 0 20px 0 20px;} .track { color: gray; } h1, h2, h4 { text-align: center; } </style>"
        let track = (item.type != "") ? "<h4 class=\"track\">Track: \(item.type)</h4>" : ""
        let html = "<html><head><meta charset=\"utf-8\">\(style)</head><body><h1>\(item.session)</h1><h2>\(item.speaker)</h2><span>\(text)</span></body>\(track)</html>"
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }


}
