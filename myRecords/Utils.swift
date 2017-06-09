//
//  Utils.swift
//  myRecords
//
//  Created by Luis Tejada on 8/6/17.
//  Copyright © 2017 Luis Tejada. All rights reserved.
//

import Foundation

class Utils {
    
    static func getDocumentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    static func getFileName(url: URL) -> String {
        
        let name = url.lastPathComponent
        let noExtention = name.replacingOccurrences(of: ".m4a", with: "")
        return noExtention
    }
}
