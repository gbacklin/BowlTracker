//
//  PropertyList.swift
//  NetworkCommunicationTests
//
//  Created by Gene Backlin on 4/5/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

open class PropertyList: NSObject {
    
    open class func readFromArchive(filename: String) -> [String : AnyObject]? {
        var data: [String : AnyObject]?
        
        if let plistPath: String = Bundle.main.path(forResource: filename, ofType: "plist") {
            if let dictData: Data = FileManager.default.contents(atPath: plistPath) {
                do {
                    try data = PropertyListSerialization.propertyList(from: dictData, options: .mutableContainersAndLeaves, format: nil) as? [String : AnyObject]
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        return data
    }
    
    open class func read(filename: String) -> [String : AnyObject]? {
        var data: [String : AnyObject]?
        
        if let plistPath: String = Bundle.main.path(forResource: filename, ofType: "plist") {
            if let aData: NSData = NSData(contentsOfFile: plistPath as String) {
                data = NSKeyedUnarchiver.unarchiveObject(with: aData as Data) as? [String : AnyObject]
                /*
                 do {
                     data = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self], from: aData as Data) as? [String : AnyObject]
                 }
                 catch let error {
                     debugPrint("unarchiveObject(with:) \(error.localizedDescription)")
                 }
                 */
            }
        }
        
        return data
    }
    
    open class func dictionaryFromPropertyList(filename: NSString) -> NSDictionary? {
        var result: NSDictionary! = nil
        
        if let bundlePath: NSString = bundlePathFor(filename: filename, fileExtension: "plist") {
            if let aData: NSData = NSData(contentsOfFile: bundlePath as String) {
                result = NSKeyedUnarchiver.unarchiveObject(with: aData as Data) as? NSDictionary
                /*
                 do {
                     result = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSObject.self], from: aData as Data) as? NSDictionary
                 }
                 catch let error {
                     debugPrint("unarchiveObject(with:) \(error.localizedDescription)")
                 }
                 */

            }
        }
        
        return result
    }
    
    open class func writePropertyListFromDictionary(filename: NSString, plistDict: NSDictionary) -> Bool {
        var result: Bool = false
        
        if let bundlePath: NSString = bundlePathFor(filename: filename, fileExtension: "plist") {
            let aData: NSData = NSKeyedArchiver.archivedData(withRootObject: plistDict) as NSData
            result = aData.write(toFile: bundlePath as String, atomically: true)
            /*
            do {
                let aData = try NSKeyedArchiver.archivedData(withRootObject: plistDict, requiringSecureCoding: false)
                result = ((try? aData.write(to: URL(fileURLWithPath: bundlePath as String), options: [.atomic])) != nil)
            } catch let error {
                debugPrint("archivedData(with:) \(error.localizedDescription)")
            }
            */
        }
        
        return result
    }
    
    class func write(_ filename: NSString, plistDict: NSDictionary) -> Bool {
        let fname: NSString = NSString(format: "%@.plist", filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let bundlePath: NSString = rootPath.appendingPathComponent(fname as String) as NSString
        var success = false
        let aData: Data = NSKeyedArchiver.archivedData(withRootObject: plistDict)
        success = ((try? aData.write(to: URL(fileURLWithPath: bundlePath as String), options: [.atomic])) != nil)
        /*
        do {
            let aData = try NSKeyedArchiver.archivedData(withRootObject: plistDict, requiringSecureCoding: false)
            success = ((try? aData.write(to: URL(fileURLWithPath: bundlePath as String), options: [.atomic])) != nil)
        } catch let error {
            debugPrint("archivedData(with:) \(error.localizedDescription)")
        }
         */
        //if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: plistDict, requiringSecureCoding: true) {
        //    try? archivedData.write(to: URL(fileURLWithPath: bundlePath as String))
        //}
        
        return success
    }

    
    // MARK: - JSON Methods
    
    open class func writeJSON(filename: NSString, json: String) {
        let bundlePath: NSString = bundlePathFor(filename: filename, fileExtension: "json")!
        
        do {
            /* writing here */
            try json.write(to: URL(fileURLWithPath: bundlePath as String), atomically: false, encoding: .utf8)
        } catch {
            /* error handling here */
            print("writeJSON error: \(error.localizedDescription)")
        }
    }
    
    open class func readJSONFIle(filename: String) -> Data? {
        var result: Data?

        if let aData: NSData = NSData(contentsOfFile: filename) {
            result = aData as Data
        }

        return result
    }
    
    open class func readJSON(filename: NSString) -> String? {
        var result: String?
        let bundlePath: NSString = bundlePathFor(filename: filename, fileExtension: "json")!
        
        do {
            /* reading here */
            result = try String(contentsOf: URL(fileURLWithPath: bundlePath as String), encoding: .utf8)
        } catch {
            /* error handling here */
            print("readJSON error: \(error.localizedDescription)")
        }
        
        return result
    }

    class func delete(_ filename: NSString) -> Bool {
        let fileManager = FileManager.default
        let fname: NSString = NSString(format: "%@.plist", filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let bundlePath: NSString = rootPath.appendingPathComponent(fname as String) as NSString
        var success = false
        
        do {
            try fileManager.removeItem(atPath: bundlePath as String)
            success = true
        } catch {
            success = false
            debugPrint(error.localizedDescription)
        }
        return success
    }
    
    // MARK: - Utility methods
    
    private class func bundlePathFor(filename: NSString, fileExtension: NSString) -> NSString? {
        let fname: NSString = NSString(format: "%@.\(fileExtension)" as NSString, filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        
        return rootPath.appendingPathComponent(fname as String) as NSString
    }
    
}

