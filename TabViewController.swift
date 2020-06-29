//
//  TabViewController.swift
//  HTPC
//
//  Created by Tyler Hall on 8/25/19.
//  Copyright © 2019 tyler,io. All rights reserved.
//

import UIKit
import SafariServices

class Tab {
    var title = ""
    var image: UIImage?
    
    struct Website {
        var title: String
        var url: URL
        var viewController: UIViewController?
        var isActive = false
    }

    var websites = [Website]()
    
    func makeActive(website: Website) {
        for i in 0..<websites.count {
            websites[i].isActive = (website.title == websites[i].title)
        }
    }
}

class TabViewController: UITabBarController {

    var tabs = [Tab]()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadTabs()
        
        tabs.forEach({
            if var website = $0.websites.first {
                website.isActive = true
            }
        })

        let vcs = tabs.compactMap({ $0.websites.first?.viewController })
        setViewControllers(vcs, animated: false)

        let gr = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        tabBar.addGestureRecognizer(gr)
    }

    func loadTabs() {
        guard let settingsURL = Bundle.main.url(forResource: "Settings", withExtension: "plist") else { fatalError() }
        guard let settingsDict = NSDictionary(contentsOf: settingsURL) as? [String : Any] else { fatalError() }
        guard let settingsTabs = settingsDict["Tabs"] as? [[String: Any]] else { fatalError() }

        tabs.removeAll()

        var tagIndex = 0
        for dict in settingsTabs {
            let tab = Tab()

            tab.title = (dict["Title"] as? String) ?? ""

            if let iconName = dict["Icon"] as? String {
                tab.image = UIImage(named: iconName)
            }
            
            var isFirst = true
            if let urls = dict["URLs"] as? [[String: Any]] {
                for urlDict in urls {
                    if let title = urlDict["Title"] as? String, let urlStr = urlDict["URL"] as? String, let url = URL(string: urlStr) {
                        let vc = SFSafariViewController(url: url)
                        vc.title = title
                        
                        let tabBarItem = UITabBarItem(title: title, image: tab.image, selectedImage: tab.image)
                        tabBarItem.tag = tagIndex
                        vc.tabBarItem = tabBarItem

                        var website = Tab.Website(title: title, url: url, viewController: vc)
                        website.isActive = isFirst
                        tab.websites.append(website)
                        
                        isFirst = false
                    }
                }
            }
            
            if tab.websites.count > 0 {
                tabs.append(tab)
                tagIndex += 1
            }
        }
    }
    

    @objc func didLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == UIGestureRecognizer.State.began else { return }
        guard let tagIndex = tabBar.selectedItem?.tag else { return }
        
        let tab = tabs[tagIndex]

        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for website in tab.websites {
            let item = UIAlertAction(title: website.title, style: .default) { (action) in
                if let webViewController = website.viewController {
                    tab.makeActive(website: website)
                    self.viewControllers?[tagIndex] = webViewController
                }
            }
            ac.addAction(item)
        }

        let item = UIAlertAction(title: "Enter URL", style: .default) { (action) in
            let inputAC = UIAlertController(title: "Enter URL", message: nil, preferredStyle: .alert)
            inputAC.addTextField { (textField) in
                
            }
            let go = UIAlertAction(title: "Go", style: .default) { (action) in
                guard let urlStr = inputAC.textFields?.first?.text, let url = URL(string: urlStr) else { return }

                if var website = tab.websites.first(where: { (w) -> Bool in
                    return w.isActive
                }) {
                    let vc = SFSafariViewController(url: url)
                    vc.tabBarItem = website.viewController?.tabBarItem
                    website.viewController = vc
                    self.viewControllers?[tagIndex] = vc
                }
            }
            inputAC.addAction(go)
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                
            }
            inputAC.addAction(cancel)
            DispatchQueue.main.async {
                self.present(inputAC, animated: true)
            }
        }
        ac.addAction(item)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cancelAction)

        present(ac, animated: true)
    }
}
