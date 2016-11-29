/*
 Developer Tools: Console
 
 DTTest.swift 11/16/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit

public class DTTest {
    private let console = DTConsole.sharedInstance
    public init() { }
    public func enableDiagnostic() { DTConsole.Settings.diagnosticMode = true }
//    public func betaAuth() {
//        console.status = 200
//        console.token = .authenticated
//        console.ex = Date() + 86400
//    }
}
