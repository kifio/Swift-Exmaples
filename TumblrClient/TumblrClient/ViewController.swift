//
//  ViewController.swift
//  TumblrClient
//
//  Created by Ivan Murashov on 10/09/2018.
//  Copyright © 2018 Ivan Murashov. All rights reserved.
//

import UIKit
import OAuthSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    static let CELL_ID = "cell"
    
    let network = Network()
    var images = [(url: String, image: UIImage?)]()
    var tag: String? = nil
    var before: Int = 0
    var imagesTableView: UITableView? = nil
    var uiSearchBar: UISearchBar? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if network.getCredential() != nil {
            network.createClient()
            showTumblr()
        } else {
            network.authorize(viewController: self)
        }
    }
    
    func showTumblr() {
        addTableView()
        addSearchBar()
    }
    
    private func addTableView() {
        imagesTableView = UITableView()
        imagesTableView!.frame = CGRect(x: 0, y: 66, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imagesTableView!.dataSource = self
        imagesTableView!.delegate = self
        imagesTableView!.register(UITableViewCell.self, forCellReuseIdentifier: ViewController.CELL_ID)
        self.view.addSubview(imagesTableView!)
    }
    
    private func addSearchBar() {
        uiSearchBar = UISearchBar()
        uiSearchBar!.frame =  CGRect(x: 0, y: 22, width: UIScreen.main.bounds.width, height: 44)
        uiSearchBar!.delegate = self
        uiSearchBar!.searchBarStyle = UISearchBarStyle.minimal
        self.view.addSubview(uiSearchBar!)
    }
    
    @objc func logout() {
        network.logout(viewController: self)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange : String) {
        if (textDidChange.count == 0) {
            clear()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.CELL_ID, for: indexPath)
        cell.imageView?.image = nil
        if let image = images[indexPath.row].image {
            setImage(cell: cell, image: image, indexPath: indexPath)
        } else {
            loadPicture(indexPath: indexPath)
        }
        return cell
    }
    
    func loadPicture(indexPath: IndexPath) {
        print("load \(images[indexPath.row].url) at \(indexPath.row)")
        self.network.loadImage(stringUrl: images[indexPath.row].url, completionHandler: { response in
            if let image = UIImage(data: response) {
                self.images[indexPath.row].image = image
                if let cell = self.imagesTableView?.cellForRow(at: indexPath) {
                    self.setImage(cell: cell, image: image, indexPath: indexPath)
                }
            }
        })
    }
    
    func setImage(cell: UITableViewCell, image: UIImage, indexPath: IndexPath) {
        var cellImg: UIImageView
        if cell.contentView.viewWithTag(1) == nil {
            cellImg = UIImageView(frame: cell.contentView.frame)
            cellImg.tag = 1
            cell.contentView.addSubview(cellImg)
        } else {
            cellImg = cell.contentView.viewWithTag(1) as! UIImageView
        }
        
        cellImg.contentMode = UIViewContentMode.center
        cellImg.image = scaleUIImageToSize(image: image, targetSize: CGSize(width: cellImg.frame.width, height: cellImg.frame.height))
    }
    
    func scaleUIImageToSize(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
    
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.width
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == images.count - 1 {
            search()
        }
    }
    
    func search() {
        clear()
        if let tag = self.tag {
            network.search(tag: tag, before: self.before, completion: { urls, before in
                self.before = before
                for url in urls {
                    self.images.append((url: url, image: nil))
                }
                self.imagesTableView!.reloadData()
            }, failure: { msg in
                print(msg)
            })
        }
    }
    
    func clear() {
        if uiSearchBar!.text != self.tag {
            self.tag = uiSearchBar!.text
            self.before = Int(NSDate().timeIntervalSince1970 * 1000)
            self.images.removeAll()
            self.imagesTableView?.reloadData()
        }
    }
}
