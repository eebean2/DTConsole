//
//  Delegate+Helper.swift
//  DTConsole
//
//  Created by Erik Bean on 12/15/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import DTConsole

class DEHelper: DTConsoleDelegate, DTCommandDelegate {
    
    let console = DTConsole.sharedInstance
    
    func didGetCommand(_ command: String, withArguments arguments: [String]?) {
        console.print("DEHelper: \(#function)", method: .both)
        if command == "test" {
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("Hi, I'm Bob!")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("Fuck off Bob!")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
            console.print("This is a test")
        }
    }
    
    func commandList() -> [String]? {
        console.print("DEHelper: \(#function)", method: .both)
        return ["test"]
    }
}
