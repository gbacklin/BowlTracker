//
//  SettingsBundleHelper .swift
//  BowlTracker
//
//  Created by Gene Backlin on 12/5/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

class SettingsBundleHelper: NSObject {
    
    class func setVersionAndBuildDate() {
        let versionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let version = "\(versionString) (\(buildString))"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        let dateString = dateFormatter.string(from: Date())

        UserDefaults.standard.set(version, forKey: "version_preference")
        UserDefaults.standard.set(dateString, forKey: "date_preference")
    }

}
