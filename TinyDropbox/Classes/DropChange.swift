//
//  DropChange.swift
//  BuchaReader
//
//  Created by Bucha Kanstantsin on 6/4/17.
//  Copyright © 2017 BuchaBros. All rights reserved.
//

import Foundation
import TBDropboxKit
import BuchaSwift

public enum DropChangeAction {
    case undefined
    case delete
    case updateFile
    case updateFolder
}

private func actionConverted(from tbChageAction: TBDropboxChangeAction) -> DropChangeAction {
    switch tbChageAction {
    case .undefined: return .undefined
    case .delete: return .delete
    case .updateFile: return .updateFile
    case .updateFolder: return .updateFolder
    }
}


open class DropChange {
    open var path: String = ""
    open var action: DropChangeAction = .undefined
    
    open func localFileURL(usingBaseURL baseURL: URL) -> URL? {
        let result = baseURL.appendingPathComponent(path)
        
        return result;
    }
    
    internal init(usingPath dropboxPath: String,
                  tbAction: TBDropboxChangeAction) {
        path = dropboxPath
        action = actionConverted(from: tbAction);
    }
}
