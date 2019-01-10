//
//  SettingsBundleHelper .swift
//  BowlTracker
//
//  Created by Gene Backlin on 12/5/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

class SettingsBundleHelper: NSObject {
    
    class func compileDate() -> Date {
        let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "Info.plist"
        if let infoPath = Bundle.main.path(forResource: bundleName, ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
        {
            return infoDate
        }
        return Date()
    }
    
    class func setVersionAndBuildDate() {
        let versionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let version = "\(versionString) (\(buildString))"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        let dateString = dateFormatter.string(from: compileDate())
        let currentDefaultsVersion = UserDefaults.standard.string(forKey: "version_preference")
        
        if version != currentDefaultsVersion {
            UserDefaults.standard.set(version, forKey: "version_preference")
            UserDefaults.standard.set(dateString, forKey: "date_preference")
        }
    }

}
