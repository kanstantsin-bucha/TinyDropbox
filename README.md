# TinyDropbox

[![CI Status](http://img.shields.io/travis/truebucha/TinyDropbox.svg?style=flat)](https://travis-ci.org/truebucha/TinyDropbox)
[![Version](https://img.shields.io/cocoapods/v/TinyDropbox.svg?style=flat)](http://cocoapods.org/pods/TinyDropbox)
[![License](https://img.shields.io/cocoapods/l/TinyDropbox.svg?style=flat)](http://cocoapods.org/pods/TinyDropbox)
[![Platform](https://img.shields.io/cocoapods/p/TinyDropbox.svg?style=flat)](http://cocoapods.org/pods/TinyDropbox)

## Brief

Easy to use dropbox sync for swift coders [wrapper on TBDropboxKit]

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

To receive server files changes set watchdogEnabled to true 

### patch info.plist file of the target

    ``
    <key>LSApplicationQueriesSchemes</key>
    <array>
		<string>dbapi-8-emm</string>
		<string>dbapi-2</string>
	</array>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>db-f73chv4vrf1uv40</string>
			</array>
			<key>CFBundleURLName</key>
			<string></string>
		</dict>
	</array>
    ``

### initialize in app delegate
    
    add properties to AppDelegate
    
    ``
    let dropboxStateChangedNotification = "dropboxStateChangedNotification"
    let dropboxStateNotificationKey = "dropboxStateNotificationKey"
    let dropbox = TinyDropbox.shared``
    
    add AppDelegate as dropbox delegate
    
    `` class AppDelegate: UIResponder, UIApplicationDelegate, TinyDropboxDelegate {``
    
    ``
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        dropbox.delegate = self
        // Override point for customization after application launch.
        return true
    }``
    
    ``
    // MARK: TinyDropboxDelegate

    func dropbox(_ dropbox: TinyDropbox, didChangeStateTo state: TinyDropboxState) {
        let userInfo = [dropboxStateNotificationKey: state]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: dropboxStateChangedNotification), object: self, userInfo: userInfo)
    }
    
    func dropbox(_ dropbox: TinyDropbox, didReceiveIncomingChanges changes: Array<DropChange>) {

    }
    ``
### handle dropbox auth redirect in an AppDelegete
    
    ``
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let result = dropbox.handleAuthorisationRedirectURL(url)
        return result
    }
    ``

### subscribe to notifications

    ``
     private func subscribeToNotifications () {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ListDropboxViewController.dropboxDidCahngeState(notification:)),
                                               name: NSNotification.Name(rawValue: appDelegate.dropboxStateChangedNotification),
                                               object: appDelegate)
    }

    func dropboxDidCahngeState (notification: NSNotification) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let state = notification.userInfo?[appDelegate.dropboxStateNotificationKey];
        
        if let state = state as? TinyDropboxState{
            if state == .connected
            || state == .reconnected {
                download(using: appDelegate.dropbox)
           }
        }
    }``
    
### list books folder and download first one if no local copy present
    
    ``
    private func download(using dropbox: TinyDropbox) {
    dropbox.append(path: "/books")
        dropbox.listDirectory { (list: DropboxFilesList, error :DropboxError?) in
            guard list != nil, list!.count > 1 else {
                return
            }
            
            var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
            path.append("/book.pdf")
            let url = URL.init(fileURLWithPath: path)
            let richable = try? url.checkResourceIsReachable()
            
            guard richable == nil || richable == false else {
                self.open(fileAt: url)
                return
            }
            
            print(url);
            
            dropbox.download(atPath: list![0], to: url, completion: { [weak self]  (error: DropboxError?) in
                if let error = error {
                    print(error)
                } else {
                    self?.open(fileAt: url)
                }
            })
        }
    }``

## Requirements

## Installation

TinyDropbox is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TinyDropbox"
```

## Author

truebucha, truebucha@gmail.com

## License

TinyDropbox is available under the MIT license. See the LICENSE file for more info.
