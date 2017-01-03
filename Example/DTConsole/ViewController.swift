//
//  ViewController.swift
//  DTConsole
//
//  Created by Erik on 11/19/2016.
//  Copyright (c) 2016 Erik. All rights reserved.
//

import UIKit
import DTConsole

class ViewController: UIViewController, DTCommandDelegate {
    
    let console = DTConsole.sharedInstance
    var setup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        console.commandDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToHome(_ segue: UIStoryboardSegue) { console.removeConsole() }
    @IBAction func displayPopover() {
        if setup {
            console.removeConsole()
        }
        let alert = UIAlertController(title: nil, message: "Would you like a console to appear from top or borrom?", preferredStyle: .alert)
        let top = UIAlertAction(title: "Top", style: .default) { (action) in
            self.console.setup(on: self, orientation: .top) { (success) in
                if success {
                    self.console.display()
                    self.setup = true
                }
            }
        }
        let bottom = UIAlertAction(title: "Bottom", style: .default) { (action) in
            self.console.setup(on: self) { (success) in
                if success {
                    self.console.display()
                    self.setup = true
                }
            }
        }
        alert.addAction(top)
        alert.addAction(bottom)
        present(alert, animated: true, completion: nil)
    }
    @IBAction func displayConsole() {
        if setup {
            console.removeConsole()
        }
        console.setup(on: self, type: .textPopover) { (success) in
            if success {
                self.console.display()
                self.setup = true
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if setup {
            console.removeConsole()
        }
        let nav = segue.destination as! UINavigationController
        let vc = nav.topViewController as! ConsoleView
        vc.type = segue.identifier!
    }
    
    func didGetCommand(_ command: String, withArguments arguments: [String]?) {
        if command == "test" {
            console.printWarning("Bob is getting angry", method: .both)
            console.print("Jim does not care. Jim says \"Fuck you Bob!\"", method: .both)
            console.printError("Bob is not angry", method: .both)
            console.printDiag("Bob is a 7 foot pissed off Russian", method: .both)
            console.printDiag("Jim is a 5 foot hipster", method: .both)
            console.printDiag("Bob will floss his teeth with Jim if he does not run NOW", method: .both)
        }
    }
    
    func commandList() -> [String]? {
        return ["test"]
    }
}
