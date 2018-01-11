//
//  FileHandler.swift
//  ReplayKitSandbox
//
//  Created by Sonam on 12/7/17.
//  Copyright © 2017 ustwo. All rights reserved.
//

import UIKit

// Referenced source code here: https://github.com/giridharvc7/ScreenRecord/blob/master/ScreenRecordDemo/Source/FileUtil.swift

@objc class FileHandler: NSObject {
    
    static let folderName = "Replays"
    
    private class func createFolder() {
        
        // path to documents directory
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        
        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
            let replayDirectoryPath = documentDirectoryPath.appending("/\(FileHandler.folderName)")
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: replayDirectoryPath) {
                do {
                    try fileManager.createDirectory(atPath: replayDirectoryPath,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
                } catch {
                    print("Error creating Replays folder in documents dir: \(error)")
                }
            }
        }
    }
    
    public class func filePath(_ fileName: String) -> String {
        
        createFolder()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        let filePath : String = "\(documentsDirectory)/\(FileHandler.folderName)/\(fileName).mp4"
        
        print("FILe handler created a path at \(filePath)")
        return filePath
    }
    
    internal class func fetchAllReplays() -> [URL] {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let replayPath = documentsDirectory?.appendingPathComponent("/\(FileHandler.folderName)") else {
            print("file path does not exist")
            return []
        }
        
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: replayPath, includingPropertiesForKeys: nil, options: [])
            return directoryContents
        } catch {
            print(error)
        }
        
        return []
    }
    
}

