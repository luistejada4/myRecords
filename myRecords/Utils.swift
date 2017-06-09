//
//  Utils.swift
//  myRecords
//
//  Created by Luis Tejada on 8/6/17.
//  Copyright © 2017 Luis Tejada. All rights reserved.
//

import Foundation

class Utils {
    
    public static func getDocumentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    public static func getFileName(url: URL) -> String {
        
        let name = url.lastPathComponent
        let noExtention = name.replacingOccurrences(of: ".m4a", with: "")
        return noExtention
    }
    
    public static func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }
}
