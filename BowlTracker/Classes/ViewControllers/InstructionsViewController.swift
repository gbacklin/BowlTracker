//
//  InstructionsViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 11/25/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController {
    var textTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Instructions"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        title = textTitle
    }

}
