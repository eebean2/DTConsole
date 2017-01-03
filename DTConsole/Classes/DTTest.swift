/*
 Developer Tools: Console
 
 DTTest.swift 12/18/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import Foundation

internal class DTTest {
    func basic(name: String? = "") {
        if name != "" {
            print("Hello, \(name!)!")
        } else {
            print("Hello!")
        }
    }
    
    func random() {
        basic()
    }
}
