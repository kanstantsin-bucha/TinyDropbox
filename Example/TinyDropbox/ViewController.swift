//
//  ViewController.swift
//  TinyDropbox
//
//  Created by truebucha on 06/06/2017.
//  Copyright (c) 2017 truebucha. All rights reserved.
//

import UIKit
import TinyDropbox

class ListDropboxViewController: UIViewController {
    let imageFile: NSString = "japan.jpg"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        subscribeToNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - events -

    func dropboxDidChangeState (notification: Notification) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let state = notification.userInfo?[appDelegate.dropboxStateNotificationKey];
        
        if let state = state as? TinyDropboxState{
            if state == .connected
            || state == .reconnected {
                download(using: appDelegate.dropbox)
           }
        }
    }
    
// MARK: - implementation -
    
    private func subscribeToNotifications () {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ListDropboxViewController.dropboxDidChangeState(notification:)),
                                               name: NSNotification.Name(rawValue: appDelegate.dropboxStateChangedNotification),
                                               object: appDelegate)
    }
    
    private func unsubscribeFromNotifications () {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func open(fileAt url: URL) {
        switch url.pathExtension.lowercased() {
        case "jpg":
            UIApplication.shared.open(url, options: [:]) { (succeed) in
                print("open jpg file \(succeed ? "succeed" : "failed")")
            }
        default:
            print("failed to open unsupported file \(String(describing: url))")
        }
    }
    
    private func download(using dropbox: TinyDropbox) {
        dropbox.append(pathComponent: "/images")
        
        let imageName = imageFile.deletingPathExtension
        
        let imageUrl = Bundle.main.url(forResource:imageName, withExtension: imageFile.pathExtension)
        
        var imagePath = dropbox.path!
        imagePath.append("/")
        imagePath.append(imageFile as String)
        
        // upload image to dropbox app folder
        // Apps/BuchaTestSuite/images
        
        dropbox.upload(
            toPath: imagePath,
            from: imageUrl!) { [weak self] (error: DropboxError?) in
                if let error = error {
                    print("Tiny Dropbox  Upload file: failed(\( error))")
                }
                else {
                    print("Tiny Dropbox  Upload file: succeed")
                }
                dropbox.listDirectory { [weak self] (list: DropboxFilesList, error: DropboxError?) in
                    guard list != nil, list!.count >= 1 else {
                        print("so you definately has no files in your dropbox Apps/BuchaTestSuite/images folder")
                        return
                    }
                    
                    var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                    path.append("/")
                    let imageFile = self?.imageFile as String?
                    path.append(imageFile!)
                    
                    let url = URL.init(fileURLWithPath: path)
                    print(url);
                    
                    let richable = try? url.checkResourceIsReachable()
                    
                    guard richable == nil || richable == false else {
                        self?.open(fileAt: url)
                        return
                    }
                    
                    print("no local file found - start downloading")
                    
                    dropbox.download(atPath: list![0], to: url, completion: { [weak self]  (error: DropboxError?) in
                        if let error = error {
                            print(error)
                        } else {
                            self?.open(fileAt: url)
                        }
                    })
                }
            }
    }
    
}

