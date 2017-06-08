# CDBDelegateCollection

Use it to handle collection of weak references to delegates. The collection calls a method on a delegate only if it respondsToSelector: succeeded. The collection accept only delegates that conform to protocol that was passed on initialization. If delegate became nil it will be deallocated instantly and reference to it will be removed on the next collection iteration.

[![CI Status](http://img.shields.io/travis/yocaminobien/CDBDelegateCollection.svg?style=flat)](https://travis-ci.org/yocaminobien/CDBDelegateCollection)
[![Version](https://img.shields.io/cocoapods/v/CDBDelegateCollection.svg?style=flat)](http://cocoapods.org/pods/CDBDelegateCollection)
[![License](https://img.shields.io/cocoapods/l/CDBDelegateCollection.svg?style=flat)](http://cocoapods.org/pods/CDBDelegateCollection)
[![Platform](https://img.shields.io/cocoapods/p/CDBDelegateCollection.svg?style=flat)](http://cocoapods.org/pods/CDBDelegateCollection)

## TODO

    * Write a documentation (HOWTO)
    * Add tests
    
## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

CDBDelegateCollection is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CDBDelegateCollection"
```

## Author

Kanstantsin Bucha, yocaminobien@gmail.com

## License

CDBDelegateCollection is available under the MIT license. See the LICENSE file for more info.
