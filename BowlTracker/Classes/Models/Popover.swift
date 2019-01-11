//
//  Popover.swift
//  BowlTracker
//
//  Created by Gene Backlin on 1/11/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import UIKit

class Popover: NSObject {
    
    static let sharedInstance = Popover()
    
    var sourceView: UIView?

    func present(viewController: UIViewController, usingSourceView: UIView, currentFrame: Frame, title: String) {
        if let controller: PopupViewController = UIStoryboard(name: "Main", bundle: Bundle(for: self.classForCoder)).instantiateViewController(withIdentifier: "PopupViewController") as? PopupViewController {
            controller.sourceView = usingSourceView
            
            // set the presentation style
            controller.modalPresentationStyle = UIModalPresentationStyle.popover
            
            // set up the popover presentation controller
            controller.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
            controller.popoverPresentationController?.delegate = controller
            controller.popoverPresentationController?.sourceView = usingSourceView //
            controller.popoverPresentationController?.sourceRect = usingSourceView.bounds
            controller.currentFrame = currentFrame
            controller.titleText = title

            // present the popover
            viewController.present(controller, animated: true, completion: nil)
        }
    }

}
