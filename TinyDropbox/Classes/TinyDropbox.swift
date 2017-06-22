//
//  Dropbox.swift
//  BuchaReader
//
//  Created by Bucha Kanstantsin on 6/2/17.
//  Copyright © 2017 BuchaBros. All rights reserved.
//

import Foundation
import TBDropboxKit
import BuchaSwift


public enum DropboxError: Error {
    case describedFailure(reason: String)
}

public enum TinyDropboxState : Int {
    case undefined
    case disconnected
    case authorization
    case connected
    case reconnected // Connected again with same user
    case paused // Disconnected but keeping authorization token
}

private func stateConverted(from tbConnectionState: TBDropboxConnectionState) -> TinyDropboxState {
    switch tbConnectionState {
    
    case .undefined: return .undefined
        
    case .disconnected: return .disconnected
        
    case .authorization: return .authorization
        
    case .connected: return .connected
    
    case .reconnected: return .reconnected
        
    case .paused: return .paused
    
    }
}

public typealias DropboxFilesList = Array<String>?


public protocol TinyDropboxDelegate {
    func dropbox(_ dropbox: TinyDropbox, didChangeStateTo state: TinyDropboxState);
    func dropbox(_ dropbox: TinyDropbox, didReceiveIncomingChanges changes: Array<DropChange>);
}


open class TinyDropbox : NSObject, TBDropboxClientDelegate {

    static public let shared = TinyDropbox()
    public let client: TBDropboxClient = TBDropboxClient.sharedInstance()
  
    public var state: TinyDropboxState {
      get {
        let state = client.connection?.state
        
        guard state != nil
         else { return .undefined }
        
        let result = stateConverted(from: state!)
        return result;
      }
    }
    
    public var delegate : TinyDropboxDelegate?
    public var path : String? = nil
    public var watchdogEnabled : Bool = false {
        didSet {
            client.watchdogEnabled = watchdogEnabled
        }
    }
    
    override init() {
        super.init();
        client.initiate(withConnectionDesired: true)
        client.add(self);
    }

// MARK: - interface -

    public func enableVerboseLogging() {
        client.logger?.logLevel = .verbose;
        client.tasksQueue.verboseLogging = true;
        client.watchdog.logger?.logLevel = .verbose;
    }

    public func handleAuthorisationRedirectURL(_ url: URL) -> Bool {
        guard client.connection != nil else {
            return false
        }
        
        let result = client.connection!.handleAuthorisationRedirectURL(url)
        return result
    }
    
    public func listDirectory(completion: @escaping DataCompletion<DropboxFilesList, DropboxError>) {
        listDirectory(atPath: path, completion: completion);
    }
    
    public func append(pathComponent: String) {
        guard path != nil else {
            path = pathComponent
            return
        }
        
        var fullPath = path!
        
        let shouldAddSlash = fullPath.hasSuffix("/") == false
                             && fullPath.hasPrefix("/") == false
        
        if (shouldAddSlash) {
            fullPath.append("/")
        }
        
        fullPath.append(pathComponent)
        
        path = fullPath
    }
    
    public func popPath () {
         guard path != nil else {
            return
        }

        var fullPath = path!
        
        let shouldRemoveSlash = fullPath.hasSuffix("/") == false
        
        if (shouldRemoveSlash) {
            let slashIndex = fullPath.characters.index(before: fullPath.characters.endIndex)
            fullPath.remove(at: slashIndex)
        }
        
        let foundRange = fullPath.range(of: "/", options: String.CompareOptions.backwards, range: nil, locale: nil)
        if let range = foundRange {
            path = fullPath.substring(to: range.lowerBound)
        } else {
            path = nil
        }
    }
    
    public func download(atPath path: String, to url: URL, completion: @escaping ErrorCompletion<DropboxError>) {
        let fileEntry = TBDropboxEntryFactory.fileEntry(usingDropboxPath: path);
        
        guard fileEntry != nil else {
            completion(DropboxError.describedFailure(reason: "failed to create file entry with path \(String(describing: path))"))
            return
        }
        
        let task = TBDropboxDownloadFileTask.init(using: fileEntry!, fileURL: url) { (task: TBDropboxTask, error: Error?) in
            guard error == nil else {
                completion(DropboxError.describedFailure(reason: "got error \(String(describing: error!))"))
                return
            }
            
            completion(nil)
        }
        
        guard task != nil else {
            completion(DropboxError.describedFailure(reason: "failed to create download task"))
            return
        }
        
        client.tasksQueue.add(task!);
    }
    
     public func upload(toPath path: String, from url: URL, completion: @escaping ErrorCompletion<DropboxError>) {
        let fileEntry = TBDropboxEntryFactory.fileEntry(usingDropboxPath: path);
        
        guard fileEntry != nil else {
            completion(DropboxError.describedFailure(reason: "failed to create file entry with path \(String(describing: path))"))
            return
        }
        
        let task = TBDropboxUploadFileTask.init(using: fileEntry!, fileURL: url) { (task: TBDropboxTask, error: Error?) in
            guard error == nil else {
                completion(DropboxError.describedFailure(reason: "got error \(String(describing: error!))"))
                return
            }
            
            completion(nil)
        }
        
        guard task != nil else {
            completion(DropboxError.describedFailure(reason: "failed to create upload task"))
            return
        }
        
        client.tasksQueue.add(task!);
    }
    
// MARK: - protocol -

// MARK: TBDropboxClientDelegate
    
    public func client(_ client: TBDropboxClient, didReceiveIncomingChanges changes: [TBDropboxChange]?) {
        guard delegate != nil else {
            return
        }
        
        let processedChanges = changes?.map({ (change: TBDropboxChange) -> DropChange in
            let processedChange = DropChange.init(usingPath: change.dropboxPath, tbAction: change.action)
            return processedChange
        })
        
        guard processedChanges != nil else {
            return
        }
        
        delegate!.dropbox(self, didReceiveIncomingChanges: processedChanges!)
    }
    
    public func dropboxConnection(_ connection: TBDropboxConnection, didChangeStateTo state: TBDropboxConnectionState) {
        let convertedState = stateConverted(from: state)
        delegate?.dropbox(self, didChangeStateTo: convertedState)
    }

// MARK: - implementation -

    private func listDirectory(atPath path: String?, completion: @escaping DataCompletion<DropboxFilesList, DropboxError>) {
    
        let rootEntry = TBDropboxEntryFactory.folderEntry(usingDropboxPath: path);
        
        guard let entry = rootEntry else {
            completion(nil, DropboxError.describedFailure(reason: "failed to create folder entry with path \(String(describing: path))"))
            return
        }
        
        
        let listTask = TBDropboxListFolderTask.init(using: entry) { (task , error) in
            guard  let folderTask = task as? TBDropboxListFolderTask, error == nil else {
                completion(nil, DropboxError.describedFailure(reason: "response returned unexpected task \(String(describing: task))"))
                return
            }

            let array = try? folderTask.folderEntries?.map{ (entry: TBDropboxEntry) throws -> String in
                return entry.dropboxPath;
            }
            
            completion(array!, nil)
        };
        
        guard listTask != nil else {
            completion(nil, DropboxError.describedFailure(reason: "failed to create list task"))
            return
        }
            
        client.tasksQueue.add(listTask!)
    }
    
}
