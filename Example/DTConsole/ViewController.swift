//
//  ViewController.swift
//  DTConsole
//
//  Created by Erik on 11/19/2016.
//  Copyright (c) 2016 Erik. All rights reserved.
//

import UIKit
import DTConsole

class ViewController: UIViewController {
    
    let console = DTConsole.sharedInstance
//    let test = DTTest()
    var setup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
    // REMOVE ME if you wish to activate with your own license
        console.setEmail("support@yourrepairnow.com")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {console.resetConsole() }
    @IBAction func displayPopover() {
        if setup {
            console.resetConsole()
        }
        console.setup(on: view)
        console.display()
        setup = true
    }
    @IBAction func displayConsole() {
        if setup {
            console.resetConsole()
        }
        console.setupTextConsole(on: view)
        console.display()
        setup = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nav = segue.destination as! UINavigationController
        let vc = nav.topViewController as! ConsoleView
        vc.type = segue.identifier!
    }
}
