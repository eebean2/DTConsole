/*
 Developer Tools: Console
 
 DTTest.swift 11/16/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit

internal class DTTest: NSObject, UITextFieldDelegate {
    static let sharedInstance = DTTest()
    private override init(){super.init(); SysConsole.prErr("No current items in testing")}
    
    // There are currently no operations in testing
}
