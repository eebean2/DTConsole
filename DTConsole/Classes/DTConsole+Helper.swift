/*
 Developer Tools: Console
 
 DTConsole+Helper.swift 11/15/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit
import Auth0
import Lock

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

internal class DTAuth {
    let console = DTConsole.sharedInstance
    
    func printStatMessage() {
        switch console.token {
        case .authenticated:
            SysConsole.prOvr(":: DTConsole :: You have successfully logged into DTSuite - DTConsole. Thank you for your purchase!")
            SysConsole.prOvr(":: DTConsole :: Did you know you can set your own command list? See the documentation under \"DTConsole - Commands\" for more details!")
            return
        case .unauthenticated:
            SysConsole.prOvr(":: Auth Error :: Please check your login credentials and try again!")
        case .expired:
            SysConsole.prErr(":: Auth Error :: Your API License has expired, please renew to re-enable all this amazing content today!")
        case .trial:
            SysConsole.prOvr(":: DTConsole :: Thank you for trying the DTConsole part of DTSuite.")
            SysConsole.prOvr(":: DTConsole :: You are covered under your trial currently, and have full access to all these great features.")
            SysConsole.prOvr(":: DTConsole :: Don't forget to upgrade today to keep these features!")
        }
    }
    
    func getStatus(_ type: String) -> Int {
        if type == "trial" {
            if console.email == nil {
                SysConsole.prOvr(":: Auth Error :: Please call DTConsole().setEmail(_:) before setup to provide the email you are verifying with")
                self.console.token = .unauthenticated
                return AuthTokenStatus.unauthenticated.value
            } else {
                self.console.token = .trial
                return AuthTokenStatus.trial.value
            }
        } else if type == "full" {
            self.console.token = .authenticated
            return AuthTokenStatus.authenticated.value
        } else if type == "expired" {
            self.console.token = .expired
            return AuthTokenStatus.expired.value
        } else {
            self.console.token = .unauthenticated
            return AuthTokenStatus.unauthenticated.value
        }
    }
    
    func login(key: String?, passcode: String?, completion:  ((A0UserProfile?) -> Void)?) {
        if let path = Bundle.main.path(forResource: "Auth0", ofType: "plist") {
            if let authDict = NSDictionary(contentsOfFile: path) {
                var nkey = key
                var code = passcode
                if key == nil {
                    nkey = authDict["APIKey"] as? String
                }
                if passcode == nil {
                    code = authDict["PassCode"] as? String
                }
                A0Lock.shared().apiClient().login(
                    withUsername: nkey!,
                    password: code!,
                    parameters: A0AuthParameters(dictionary: [A0ParameterConnection : "API-Key-Database"]),
                    success: { (profile, token) in
                        if completion != nil {
                            completion!(profile)
                        }
                        self.verify(for: profile, token: token)
                        self.console.localToken = token
                }, failure: { (error) in
                    SysConsole.prOvr(":: Auth Error :: Oops something went wrong: \(error.localizedDescription)")
                    if completion != nil {
                        completion!(nil)
                    }
                })
            }
        }
    }
    
    private func verify(for profile: A0UserProfile, token: A0Token) {
        
        if DTConsole.Settings.diagnosticMode {
            SysConsole.prOvr(":: ---------------------------------------------------- ::")
            SysConsole.prDiag("Auth :: Profile ID: \(profile.userId)")
            SysConsole.prDiag("Auth :: Profile Name: \(profile.name)")
            SysConsole.prDiag("Auth :: Profile Nickname: \(profile.nickname)")
            SysConsole.prOvr(":: ---------------------------------------------------- ::")
            SysConsole.prOvr(":: DTConsole :: Verifying the user data")
        }
        if console.token == .trial {
            var users = profile.userMetadata["users"] as! Array<Dictionary<String, Any>>
            var date = Date()
            for user in users {
                if user["email"] as? String == console.email! {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    date = formatter.date(from: user["date"] as! String)!
                    if date < Date() {
                        console.token = .expired
                        console.status = 0
                        SysConsole.prErr("Expired token found, resetting the console")
                        console.resetConsole()
                    }
                } else if console.email != nil {
                    SysConsole.prOvr(":: DTConsole :: Please enjoy your trial!")
                    let tLenght = profile.appMetadata["trial"] as! Int
                    date = Date().addingTimeInterval(TimeInterval(tLenght * 86400))
                    console.ex = date
                    let newUser: [String: Any] = ["email": console.email!, "date": String(describing: date)]
                    users.append(newUser)
                    Auth0.users(token: token.idToken)
                        .patch(profile.userId, userMetadata: ["users" : users])
                        .start({ (results) in
                            switch results {
                            case .success(result: let userInfo):
                                SysConsole.prOvr("User Info: \(userInfo)")
                            case .failure(error: let error):
                                SysConsole.prErr("Auth :: Could not update user. \(error)")
                            }
                        })
                } else {
                    SysConsole.prErr("Auth :: Please call DTConsole().setEmail(_:) before setup to provide the email you are verifying with")
                }
            }
        } else if console.token == .unauthenticated {
            self.printStatMessage()
            return
        } else {
            if profile.userMetadata["date"] as? Date != nil {
                if (profile.userMetadata["date"] as! Date) < Date() {
                    console.token = .expired
                    console.status = 0
                    SysConsole.prErr("Expired token found, resetting the console")
                    console.resetConsole()
                }
            } else {
                let years = profile.appMetadata["lengthYears"] as! Int
                let days = profile.appMetadata["lengthDays"] as! Int
                let totalTime = (days + (years / 365)) * 86400
                let date = Date() + TimeInterval(totalTime)
                console.ex = date
                Auth0.users(token: token.idToken)
                    .patch(profile.userId, userMetadata: ["date" : date])
                    .start({ (results) in
                        switch results {
                        case .success(result: let userInfo):
                            SysConsole.prOvr("User Info: \(userInfo)")
                        case .failure(error: let error):
                            SysConsole.prErr("Auth :: Could not update user. \(error)")
                        }
                    })
            }
        }
        self.printStatMessage()
    }
}
