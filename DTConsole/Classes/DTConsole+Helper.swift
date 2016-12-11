/*
 Developer Tools: Console
 
 DTConsole+Helper.swift 11/15/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit

/// The orientation in which the console will display
@available(watchOS, unavailable, message: "Please connect to an iPhone using Conosle to enable custom watchOS logging")
public enum ConsoleOrientation {
    /// Console will display from the top
    @available(tvOS, unavailable, message: "You can only use default on tvOS")
    case top
    /// Console will display from the bottom
    @available(tvOS, unavailable, message: "You can only use default on tvOS")
    case bottom
    /// Console will display along the left side
    @available(tvOS, unavailable, message: "You can only use default on tvOS")
    case left
    /// Console will display along the right side
    @available(tvOS, unavailable, message: "You can only use default on tvOS")
    case right
    /// Console will default to the bottom
    case `default`
}

/// The method in which the console will print
@available(watchOS, unavailable, message: "Please connect to an iPhone using Conosle to enable custom watchOS logging")
public enum PrintMethod {
    /// Prints to the CCConsole console only
    case `default`
    /// Prints to both consoles
    case both
    /// Acts like a normal print command
    case xcodeOnly
}

/// The current state of the console
@available(watchOS, unavailable, message: "Please connect to an iPhone using Conosle to enable custom watchOS logging")
public enum ConsoleState {
    /// The console is currently open
    case open
    /// The console is in fullscreen
    case fullscreen
    /// The console is closed
    case close
    /// The console is displayed as a view
    case asView
}

@available(watchOS, unavailable, message: "Please connect to an iPhone using DTConosle to enable custom watchOS logging")
@objc public protocol DTConsoleDelegate: class {
    /// Console has opened
    @objc optional func consoleDidOpen()
    /// Console has closed
    @objc optional func consoleDidClose()
    /// Console has launched fullscreen
    @objc optional func launchedFullscreen()
    /// Console has exited fullscreen
    @objc optional func closedFullscreen()
}

internal enum StockCommands: String {
    case enterFS =          "enterfullscreen"
    case exitFS =           "exitfullscreen"
    case close =            "closeconosle"
    case enableDiag =       "enablediag"
    case disableDiag =      "disablediag"
    case diagTextColor =    "diagtextcolor"
    case diagBackground =   "diagbackgroundcolor"
    case background =       "backgroundcolor"
    case textColor =        "textcolor"
    case textBox =          "textboxcolor"
    case reset =            "consolereset"
}

@available(watchOS, unavailable, message: "Please connect to an iPhone using DTConsole to use commands")
public protocol DTCommandDelegate: class {
    func didGetCommand(_ command: String, withArguments arguments: [String]?)
    func commandList() -> [String]?
}

internal class SysConsole {
    static func prOvr<t>(_ item: t) {
        print(item)
    }
    
    static func prErr(_ error: String) {
        let name = Bundle.main.infoDictionary![kCFBundleNameKey as String]!
        print(":: \(name) Console Error :: \(error)")
    }
    
    static func prDiag<t>(_ diag: t) {
        print(":: DIAGNOSTIC :: \(diag)")
    }
}

internal enum AuthTokenStatus: CustomStringConvertible {
    case unauthenticated
    case authenticated
    case expired
    case trial
    var description: String {
        switch self {
        case .unauthenticated: return "unauthenticated"
        case .authenticated: return "authenticated"
        case .expired: return "expired"
        case .trial: return "a trial user"
        }
    }
    var value: Int {
        switch self {
        case .unauthenticated, .expired: return 0
        case .authenticated, .trial: return 200
        }
    }
}

internal struct Platform {
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
}
