//
//  ConsoleView.swift
//  DTConsole
//
//  Created by Erik Bean on 11/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import DTConsole

class ConsoleView: UIViewController {
    
    var type = String()
    let console = DTConsole.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if type == "textbox" {
            console.setupTextConsoleAndDisplay(in: view)
        } else if type == "console" {
            console.setupAndDisplay(in: view)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
