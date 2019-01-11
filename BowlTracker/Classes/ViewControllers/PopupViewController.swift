//
//  PopupViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 1/11/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController {
    
    @IBOutlet weak var pinStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var sourceView: AnyObject?
    var currentFrame: Frame?
    var bowlingPins: [UIButton] = [UIButton]()
    var titleText: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.text = titleText!

        initializePinArray(subviews: pinStackView)
        
        for bowlingPin in bowlingPins {
            bowlingPin.setTitleColor(.red, for: .normal)
        }
        
        for pinIndex in currentFrame!.ball1Pins {
            for pin in bowlingPins {
                if pin.tag == pinIndex {
                    pin.setTitleColor(.darkGray, for: .normal)
                }
            }
        }
        
        for pinIndex in currentFrame!.ball2Pins {
            for pin in bowlingPins {
                if pin.tag == pinIndex {
                    pin.setTitleColor(.blue, for: .normal)
                }
            }
        }
        
    }
    
    func initializePinArray(subviews: UIStackView) {
        for subView in subviews.subviews {
            if let stackView = subView as? UIStackView {
                initializePinArray(subviews: stackView)
            } else if let button = subView as? UIButton {
                let image = UIImage(named: "gray")
                button.setBackgroundImage(image, for: .normal)
                bowlingPins.append(button)
            } else {
                print("Unknown object: \(subView)")
            }
        }
    }

}

extension PopupViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
