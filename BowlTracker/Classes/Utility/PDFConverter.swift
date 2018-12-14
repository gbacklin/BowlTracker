//
//  PDFConverter.swift
//  TestInAppPurchases
//
//  Created by Gene Backlin on 12/12/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit
import QuartzCore

class PDFConverter: NSObject {
    
    // MARK: - PDF convert view method
    
    static func convertView(view: UIView) -> Data {
        // Creates a mutable data object for updating with binary data, like a byte array
        let pdfData = NSMutableData()
        
        // Points the pdf converter to the mutable data object and to the UIView to be converted
        UIGraphicsBeginPDFContextToData(pdfData, view.bounds, nil)
        UIGraphicsBeginPDFPage()
        let pdfContext: CGContext = UIGraphicsGetCurrentContext()!
        
        // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData
        view.layer.render(in: pdfContext)
        
        // remove PDF rendering context
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
    
    // MARK: - PDF saving method
    
    static func savePDF(to filename: String, pdfData data: NSData, completion: ((String) -> Void)? = nil) {
        let documentDirectories: NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory: NSString = documentDirectories.object(at: 0) as! NSString
        let documentDirectoryFilename = documentDirectory.appendingPathComponent(filename)
        
        data.write(toFile: documentDirectoryFilename, atomically: true)
        if let completionBlock = completion {
            completionBlock("File was saved to \(documentDirectoryFilename)")
        }
    }
    
}
