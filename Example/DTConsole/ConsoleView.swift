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
            console.setup(on: self, type: .textView, completion: nil)
        } else if type == "console" {
            console.setup(on: self, type: .view, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clear() {
        console.clear()
    }
}
